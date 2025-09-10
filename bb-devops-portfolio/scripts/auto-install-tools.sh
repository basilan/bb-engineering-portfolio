#!/bin/bash
# Automated Tool Installation for BB DevOps Portfolio
# Handles missing tool installation with user permission and validation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function with timestamps
log() {
    echo -e "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1"
}

log_success() {
    echo -e "${GREEN}$(date '+%Y-%m-%d %H:%M:%S')${NC} - ✅ $1"
}

log_warning() {
    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')${NC} - ⚠️  $1"
}

log_error() {
    echo -e "${RED}$(date '+%Y-%m-%d %H:%M:%S')${NC} - ❌ $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            echo "debian"
        elif [ -f /etc/redhat-release ]; then
            echo "redhat"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "msys" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Check if tool is installed and get version
check_tool() {
    local tool="$1"
    local version_cmd="$2"
    
    if command -v "$tool" >/dev/null 2>&1; then
        local version=$(eval "$tool $version_cmd" 2>&1 | head -1)
        log_success "$tool found: $version"
        return 0
    else
        log_warning "$tool not found"
        return 1
    fi
}

# Install tool based on OS
install_tool() {
    local tool="$1"
    local os="$2"
    
    log "Installing $tool for $os..."
    
    case "$tool" in
        "ansible")
            case "$os" in
                "macos")
                    if command -v brew >/dev/null 2>&1; then
                        brew install ansible
                    else
                        pip3 install ansible
                    fi
                    ;;
                "debian")
                    sudo apt update && sudo apt install -y ansible
                    ;;
                "redhat")
                    sudo dnf install -y ansible
                    ;;
                *)
                    pip3 install ansible
                    ;;
            esac
            ;;
        "terraform")
            case "$os" in
                "macos")
                    if command -v brew >/dev/null 2>&1; then
                        brew tap hashicorp/tap && brew install hashicorp/tap/terraform
                    else
                        install_terraform_direct
                    fi
                    ;;
                "debian")
                    install_terraform_hashicorp_repo
                    ;;
                "redhat")
                    sudo dnf install -y dnf-plugins-core
                    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
                    sudo dnf install -y terraform
                    ;;
                *)
                    install_terraform_direct
                    ;;
            esac
            ;;
        "aws")
            install_aws_cli "$os"
            ;;
        *)
            log_error "Unknown tool: $tool"
            return 1
            ;;
    esac
}

# Install Terraform directly
install_terraform_direct() {
    local version="1.6.6"
    local arch="amd64"
    if [[ "$(uname -m)" == "arm64" ]]; then
        arch="arm64"
    fi
    local os_name="linux"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        os_name="darwin"
    fi
    
    log "Installing Terraform $version directly..."
    wget -q "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_${os_name}_${arch}.zip"
    unzip -q "terraform_${version}_${os_name}_${arch}.zip"
    sudo mv terraform /usr/local/bin/
    rm "terraform_${version}_${os_name}_${arch}.zip"
}

# Install Terraform from HashiCorp repo
install_terraform_hashicorp_repo() {
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install -y terraform
}

# Install AWS CLI
install_aws_cli() {
    local os="$1"
    
    case "$os" in
        "macos")
            curl -s "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
            sudo installer -pkg AWSCLIV2.pkg -target /
            rm AWSCLIV2.pkg
            ;;
        "linux"|"debian"|"redhat")
            curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip -q awscliv2.zip
            sudo ./aws/install --update
            rm -rf awscliv2.zip aws/
            ;;
        *)
            log_error "Unsupported OS for AWS CLI installation: $os"
            return 1
            ;;
    esac
}

# Main installation logic
main() {
    log "🚀 BB DevOps Portfolio - Automated Tool Installation"
    log "================================================="
    
    local os=$(detect_os)
    log "Detected OS: $os"
    
    # Define required tools and their version check commands
    local tools="python3:--version git:--version terraform:version ansible:--version aws:--version"
    
    local missing_tools=()
    local found_tools=()
    
    log "🔍 Checking existing tool installations..."
    
    # Check what's already installed
    for tool_spec in $tools; do
        local tool=$(echo "$tool_spec" | cut -d: -f1)
        local version_cmd=$(echo "$tool_spec" | cut -d: -f2)
        
        if check_tool "$tool" "$version_cmd"; then
            found_tools+=("$tool")
        else
            missing_tools+=("$tool")
        fi
    done
    
    log_success "Found ${#found_tools[@]} tools: ${found_tools[*]}"
    
    if [ ${#missing_tools[@]} -eq 0 ]; then
        log_success "All required tools are already installed!"
        return 0
    fi
    
    log_warning "Missing ${#missing_tools[@]} tools: ${missing_tools[*]}"
    
    # Ask for permission to install
    echo ""
    echo -e "${YELLOW}The following tools need to be installed:${NC}"
    for tool in "${missing_tools[@]}"; do
        echo -e "  - ${BLUE}$tool${NC}"
    done
    echo ""
    
    read -p "Install missing tools automatically? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Installation cancelled by user"
        log "Please install missing tools manually or re-run with 'y'"
        return 1
    fi
    
    # Install missing tools
    log "🔧 Installing missing tools..."
    
    for tool in "${missing_tools[@]}"; do
        # Skip python3 and git as they should be system-installed
        if [[ "$tool" == "python3" || "$tool" == "git" ]]; then
            log_error "$tool must be installed manually - see DEVELOPER_SETUP.md"
            continue
        fi
        
        if install_tool "$tool" "$os"; then
            log_success "$tool installed successfully"
        else
            log_error "Failed to install $tool"
            return 1
        fi
    done
    
    log "🔍 Validating installations..."
    
    # Re-check all tools
    local validation_failed=0
    for tool_spec in $tools; do
        local tool=$(echo "$tool_spec" | cut -d: -f1)
        local version_cmd=$(echo "$tool_spec" | cut -d: -f2)
        
        if ! check_tool "$tool" "$version_cmd"; then
            validation_failed=1
        fi
    done
    
    if [ $validation_failed -eq 1 ]; then
        log_error "Tool validation failed - please check installation"
        return 1
    fi
    
    log_success "All tools successfully installed and validated!"
    log "✅ Ready for steel-thread execution"
    
    return 0
}

# Run main function
main "$@"