#!/bin/bash
# Comprehensive CLI tool detection for BB DevOps Portfolio
# Finds tools in common installation locations regardless of current PATH

# Common installation paths to search
SEARCH_PATHS=(
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/opt/homebrew/bin"                    # macOS Apple Silicon Homebrew
    "/usr/local/homebrew/bin"              # macOS Intel Homebrew  
    "$HOME/.local/bin"                     # pip user installs
    "/opt/local/bin"                       # MacPorts
    "/snap/bin"                            # Ubuntu Snap packages
    "/usr/local/terraform"                 # Custom Terraform installs
    "/usr/local/ansible/bin"               # Custom Ansible installs
    "/opt/ansible/bin"                     # Enterprise Ansible installs
    "$HOME/bin"                            # User binaries
    "$HOME/.cargo/bin"                     # Rust tools
    "/usr/local/aws-cli/v2/current/bin"    # AWS CLI v2 default install
    "/Library/Frameworks/Python.framework/Versions/3.13/bin"  # Python.org macOS installs
    "/Library/Frameworks/Python.framework/Versions/3.12/bin"
    "/Library/Frameworks/Python.framework/Versions/3.11/bin"
    "/opt/homebrew/lib/python3.13/site-packages/bin"          # Homebrew Python packages
    "/opt/homebrew/lib/python3.12/site-packages/bin"
    "/opt/homebrew/lib/python3.11/site-packages/bin" 
    "$HOME/Library/Python/3.13/bin"       # macOS user Python installs
    "$HOME/Library/Python/3.12/bin"
    "$HOME/Library/Python/3.11/bin"
)

# Function to find a command in search paths
find_command() {
    local cmd="$1"
    
    # First check if it's already in PATH
    if command -v "$cmd" >/dev/null 2>&1; then
        command -v "$cmd"
        return 0
    fi
    
    # Search in common installation locations
    for path in "${SEARCH_PATHS[@]}"; do
        if [ -x "$path/$cmd" ]; then
            echo "$path/$cmd"
            return 0
        fi
    done
    
    # Fallback: aggressive search in common directories
    for search_dir in "/usr/local" "/opt/homebrew" "$HOME/.local" "$HOME/Library/Python" "/Library/Frameworks/Python.framework"; do
        if [ -d "$search_dir" ]; then
            found_path=$(find "$search_dir" -name "$cmd" -type f -executable 2>/dev/null | head -1)
            if [ -n "$found_path" ]; then
                echo "$found_path"
                return 0
            fi
        fi
    done
    
    # Try some common variations
    case "$cmd" in
        "python3")
            for version in python3.12 python3.11 python3.10 python3.9; do
                if result=$(find_command "$version"); then
                    echo "$result"
                    return 0
                fi
            done
            ;;
        "ansible")
            if result=$(find_command "ansible-playbook"); then
                # If ansible-playbook exists, ansible is in the same directory
                ansible_dir=$(dirname "$result")
                if [ -x "$ansible_dir/ansible" ]; then
                    echo "$ansible_dir/ansible"
                    return 0
                fi
            fi
            ;;
    esac
    
    return 1
}

# Function to validate tool and get version
validate_tool() {
    local tool_name="$1"
    local cmd_path="$2"
    local version_arg="$3"
    
    if [ ! -x "$cmd_path" ]; then
        echo "❌ $tool_name: Not executable at $cmd_path"
        return 1
    fi
    
    # Get version
    version_output=$($cmd_path $version_arg 2>&1 | head -1 2>/dev/null)
    echo "✅ $tool_name: $cmd_path"
    echo "   Version: $version_output"
    return 0
}

# Main tool validation
echo "🔍 Comprehensive Tool Detection"
echo "==============================="

# Track results
MISSING_TOOLS=0
FOUND_TOOLS=0

# Required tools and their version commands (tool:version_arg format)
REQUIRED_TOOLS="terraform:version ansible:--version ansible-playbook:--version aws:--version python3:--version git:--version"

# Find and validate each tool
for tool_spec in $REQUIRED_TOOLS; do
    tool=$(echo "$tool_spec" | cut -d: -f1)
    version_arg=$(echo "$tool_spec" | cut -d: -f2)
    
    echo ""
    echo "Searching for $tool..."
    
    if tool_path=$(find_command "$tool"); then
        if validate_tool "$tool" "$tool_path" "$version_arg"; then
            FOUND_TOOLS=$((FOUND_TOOLS + 1))
            
            # Export path for use in Makefile
            tool_var=$(echo "$tool" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
            echo "export ${tool_var}_PATH=\"$tool_path\""
        else
            echo "❌ $tool: Found but validation failed"
            MISSING_TOOLS=$((MISSING_TOOLS + 1))
        fi
    else
        echo "❌ $tool: Not found in any standard location"
        echo "   Search paths: ${SEARCH_PATHS[*]}"
        MISSING_TOOLS=$((MISSING_TOOLS + 1))
    fi
done

echo ""
echo "📊 Detection Summary"
echo "==================="
echo "✅ Found: $FOUND_TOOLS tools"
echo "❌ Missing: $MISSING_TOOLS tools"

if [ $MISSING_TOOLS -eq 0 ]; then
    echo ""
    echo "🎉 All required tools found!"
    echo "✅ Ready for steel-thread validation"
    exit 0
else
    echo ""
    echo "⚠️  Missing tools detected"
    echo "📚 Install missing tools or update PATH"
    echo "   Full setup guide: see DEVELOPER_SETUP.md"
    exit 1
fi