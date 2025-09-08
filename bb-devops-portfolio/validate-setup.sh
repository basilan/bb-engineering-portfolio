#!/bin/bash
# Validate developer setup for bb-devops-pipeline
# Run this script before attempting the demo

echo "🔍 BB DevOps Pipeline - Setup Validation"
echo "========================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track validation results
ERRORS=0
WARNINGS=0

# Function to check command availability
check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        echo -e "✅ ${GREEN}$1${NC} found: $(command -v $1)"
        return 0
    else
        echo -e "❌ ${RED}$1${NC} not found or not in PATH"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to check version
check_version() {
    local cmd="$1"
    local version_arg="$2"
    local min_version="$3"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        actual_version=$($cmd $version_arg 2>/dev/null | head -1)
        echo "   Version: $actual_version"
    fi
}

echo ""
echo "📋 Checking Core Tools"
echo "---------------------"

# Check Python
if check_command "python3.11"; then
    check_version "python3.11" "--version" "3.11"
elif check_command "python3"; then
    check_version "python3" "--version" "3.8"
    echo -e "   ${YELLOW}Warning: Python 3.11+ recommended${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo "   Please install Python 3.11+ or ensure it's in PATH"
fi

# Check Git
check_command "git"
check_version "git" "--version"

echo ""
echo "🏗️ Checking Infrastructure Tools"
echo "--------------------------------"

# Check Terraform
if check_command "terraform"; then
    check_version "terraform" "version"
    # Check if version is 1.5+
    tf_version=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4)
    if [ ! -z "$tf_version" ]; then
        echo "   Terraform version: $tf_version"
    fi
else
    echo "   Install: https://developer.hashicorp.com/terraform/downloads"
fi

# Check Ansible
if check_command "ansible"; then
    check_version "ansible" "--version"
elif check_command "ansible-playbook"; then
    check_version "ansible-playbook" "--version"
else
    echo "   Install: pip3 install ansible"
fi

# Check AWS CLI
if check_command "aws"; then
    check_version "aws" "--version"
else
    echo "   Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
fi

echo ""
echo "🔑 Checking Credentials & Keys"
echo "------------------------------"

# Check AWS credentials
if aws sts get-caller-identity >/dev/null 2>&1; then
    aws_account=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    aws_user=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)
    echo -e "✅ ${GREEN}AWS credentials${NC} configured"
    echo "   Account: $aws_account"
    echo "   User: $aws_user"
else
    echo -e "❌ ${RED}AWS credentials${NC} not configured or invalid"
    echo "   Run: aws configure"
    ERRORS=$((ERRORS + 1))
fi

# Check SSH keys
if [ -f ~/.ssh/id_rsa.pub ]; then
    key_type=$(head -c 10 ~/.ssh/id_rsa.pub)
    key_size=$(wc -c < ~/.ssh/id_rsa.pub)
    echo -e "✅ ${GREEN}SSH public key${NC} found: ~/.ssh/id_rsa.pub"
    echo "   Type: $key_type..."
    echo "   Size: $key_size bytes"
else
    echo -e "❌ ${RED}SSH public key${NC} not found: ~/.ssh/id_rsa.pub"
    echo "   Generate: ssh-keygen -t rsa -b 4096"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "🐍 Checking Python Dependencies"
echo "-------------------------------"

# Check Python packages
python_cmd="python3.11"
if ! command -v python3.11 >/dev/null 2>&1; then
    python_cmd="python3"
fi

packages=("boto3" "pytest" "requests")
for package in "${packages[@]}"; do
    if $python_cmd -c "import $package" 2>/dev/null; then
        version=$($python_cmd -c "import $package; print($package.__version__)" 2>/dev/null)
        echo -e "✅ ${GREEN}$package${NC} installed: $version"
    else
        echo -e "❌ ${RED}$package${NC} not installed"
        echo "   Install: pip3 install $package"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""
echo "📁 Checking Project Configuration"
echo "---------------------------------"

# Check terraform.tfvars
if [ -f "terraform/terraform.tfvars" ]; then
    echo -e "✅ ${GREEN}terraform.tfvars${NC} exists"
    
    # Check for real SSH key
    if grep -q "ssh-rsa\|ssh-ed25519" terraform/terraform.tfvars; then
        echo "   ✅ Real SSH key found"
    else
        echo -e "   ❌ ${RED}Real SSH key missing${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Check for placeholder email
    if grep -q "REPLACE-WITH-YOUR-EMAIL" terraform/terraform.tfvars; then
        echo -e "   ⚠️  ${YELLOW}Placeholder email needs replacement${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "   ✅ Email configured"
    fi
else
    echo -e "❌ ${RED}terraform.tfvars${NC} missing"
    echo "   Run: make setup"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "📊 Validation Summary"
echo "===================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "🎉 ${GREEN}Perfect!${NC} All requirements satisfied"
    echo "✅ Ready to run: make steel-thread"
    echo "✅ Ready to run: make demo"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "⚠️  ${YELLOW}$WARNINGS warning(s)${NC} - demo should work but review warnings"
    echo "✅ Ready to run: make steel-thread"
    echo "⚠️  May have issues with: make demo"
    exit 0
else
    echo -e "❌ ${RED}$ERRORS error(s)${NC} found - please fix before running demo"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "⚠️  ${YELLOW}$WARNINGS warning(s)${NC} also found"
    fi
    echo ""
    echo "📚 Setup Help:"
    echo "   Full guide: See DEVELOPER_SETUP.md"
    echo "   Quick start: make setup"
    echo "   Validate: ./validate-setup.sh"
    exit 1
fi