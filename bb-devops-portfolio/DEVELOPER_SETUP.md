# 🚀 Developer Setup Guide - BB DevOps Pipeline

## 📋 **Prerequisites**

This guide ensures **100% success rate** for developers running the steel-thread demo. Follow every step to avoid issues.

### **1. System Requirements**

**Supported Platforms**:
- ✅ macOS (Intel/Apple Silicon)
- ✅ Linux (Ubuntu 20.04+, CentOS 8+)
- ✅ Windows (WSL2 required)

**Minimum Specs**:
- 8GB RAM
- 10GB free disk space
- Internet connection for AWS API calls

### **2. Required Software Installation**

#### **A. Core Tools**

**Python 3.11+**:
```bash
# macOS (Homebrew)
brew install python@3.11

# Ubuntu/Debian
sudo apt update && sudo apt install python3.11 python3.11-pip

# CentOS/RHEL
sudo dnf install python3.11 python3.11-pip

# Verify installation
python3.11 --version
# Expected: Python 3.11.x
```

**Git**:
```bash
# macOS
brew install git

# Ubuntu/Debian
sudo apt install git

# CentOS/RHEL
sudo dnf install git
```

#### **B. Infrastructure Tools**

**Terraform 1.5+**:
```bash
# Method 1: Official HashiCorp Repository (Recommended)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Method 2: Direct Download
TERRAFORM_VERSION="1.6.6"
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# macOS (Homebrew)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verify installation
terraform --version
# Expected: Terraform v1.5+ (any version 1.5 or higher)
```

**Ansible 2.9+**:
```bash
# Method 1: pip (Recommended for latest version)
pip3.11 install ansible

# Method 2: Package manager
# Ubuntu/Debian
sudo apt install ansible

# CentOS/RHEL
sudo dnf install ansible

# macOS
brew install ansible

# Verify installation
ansible --version
# Expected: ansible [core 2.9+]
```

**AWS CLI v2**:
```bash
# Linux x86_64
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# macOS
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Verify installation
aws --version
# Expected: aws-cli/2.x.x
```

### **3. PATH Configuration**

**Critical**: Many developers fail because tools aren't in PATH. Add these to your shell profile:

**For Bash (`~/.bashrc` or `~/.bash_profile`)**:
```bash
# Essential PATH additions for bb-devops-pipeline
export PATH="/usr/local/bin:$PATH"                    # Common tool location
export PATH="$HOME/.local/bin:$PATH"                  # pip installed tools
export PATH="/opt/homebrew/bin:$PATH"                 # macOS Apple Silicon Homebrew
export PATH="/usr/local/opt/python@3.11/bin:$PATH"    # Specific Python version

# Terraform (if installed to custom location)
export PATH="/usr/local/terraform:$PATH"

# Ansible (if pip installed)
export PATH="$HOME/.local/bin:$PATH"

# Python aliases for consistency
alias python3='python3.11'
alias pip3='pip3.11'
```

**For Zsh (`~/.zshrc`)**:
```zsh
# Essential PATH additions for bb-devops-pipeline
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/usr/local/opt/python@3.11/bin:$PATH"

# Tool-specific paths (adjust based on your installation)
export PATH="/usr/local/terraform:$PATH"

# Python configuration
alias python3='python3.11'
alias pip3='pip3.11'
```

**Apply Changes**:
```bash
# Reload shell configuration
source ~/.bashrc    # or ~/.zshrc

# Verify all tools are found
which terraform
which ansible
which aws
which python3.11
```

### **4. AWS Account Setup**

#### **A. AWS Account Requirements**
- ✅ AWS account with billing enabled
- ✅ IAM user with programmatic access
- ✅ Budget alerts configured (recommended)

#### **B. Required IAM Permissions**
Create IAM user with these managed policies:
- `EC2FullAccess`
- `VPCFullAccess`
- `S3FullAccess`
- `CloudWatchFullAccess`
- `IAMReadOnlyAccess` (for resource tagging)
- `BudgetsFullAccess` (for cost controls)

#### **C. AWS CLI Configuration**
```bash
# Configure AWS credentials
aws configure
# AWS Access Key ID: [Your actual access key]
# AWS Secret Access Key: [Your actual secret key]
# Default region name: us-east-1
# Default output format: json

# Verify configuration
aws sts get-caller-identity
# Should return your AWS account details
```

### **5. SSH Key Setup**

**Generate SSH Key Pair** (if you don't have one):
```bash
# Generate 4096-bit RSA key
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/id_rsa

# Verify keys exist
ls -la ~/.ssh/
# Should show: id_rsa (private) and id_rsa.pub (public)

# Display public key (needed for configuration)
cat ~/.ssh/id_rsa.pub
# Copy this output - you'll need it for terraform.tfvars
```

### **6. Python Dependencies**

```bash
# Install required Python packages
pip3.11 install boto3 pytest requests ansible

# Verify installations
python3.11 -c "import boto3, pytest, requests; print('All Python dependencies installed')"
```

---

## 🔧 **Project Setup**

### **1. Clone and Navigate**
```bash
git clone <your-repo-url>
cd bb-engineering-portfolio/bb-iac-integrated-pipeline
```

### **2. Create Real Configuration**

**Create `terraform/terraform.tfvars`** with your real values:
```hcl
# Real AWS configuration
aws_region = "us-east-1"
environment = "dev"
instance_type = "t3.micro"

# Your actual SSH public key (paste from: cat ~/.ssh/id_rsa.pub)
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... [your-actual-key]"

# Your real email for AWS budget alerts
notification_email = "your-real-email@domain.com"

# Optional: Restrict SSH access (default allows all IPs)
allowed_cidr_blocks = ["0.0.0.0/0"]  # Change to your IP for security
```

### **3. Verify Setup**
```bash
# Run setup verification
make setup

# Expected output:
# ✅ Environment setup complete
```

---

## 🚀 **Running the Demo**

### **Full Steel-Thread Demo**
```bash
# Complete deployment cycle (5-7 minutes)
make demo
# This will:
# 1. Deploy real AWS infrastructure
# 2. Configure with Ansible
# 3. Run integration tests
# 4. Show live URLs
# 5. Auto-cleanup after confirmation
```

### **Step-by-Step Execution**
```bash
# 1. Validate configuration
make validate

# 2. Deploy infrastructure only
make deploy

# 3. Configure servers
make configure

# 4. Run tests
make test

# 5. Clean up when done
make destroy
```

---

## 🔍 **Troubleshooting Common Issues**

### **Command Not Found Errors**
```bash
# If tools not found, check PATH
echo $PATH
which terraform ansible aws python3.11

# Add missing paths to shell profile
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### **AWS Permission Errors**
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check IAM permissions in AWS Console
# Ensure your user has EC2, VPC, S3, CloudWatch access
```

### **SSH Key Issues**
```bash
# Ensure SSH key exists and has correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Verify key format
head -c 50 ~/.ssh/id_rsa.pub
# Should start with: ssh-rsa AAAAB3NzaC1yc2E
```

### **Terraform Issues**
```bash
# Clean Terraform state if corrupted
make clean

# Re-initialize
cd terraform && terraform init
```

---

## ✅ **Verification Checklist**

Before running the demo, ensure:

- [ ] All tools installed and in PATH
- [ ] AWS CLI configured with valid credentials
- [ ] SSH keys generated and accessible
- [ ] terraform.tfvars created with real values
- [ ] `make setup` completes successfully
- [ ] Python dependencies installed

**Success Criteria**: `make steel-thread` shows all ✅ marks

---

## 🆘 **Getting Help**

If you encounter issues:

1. **Check Prerequisites**: Ensure all software is installed correctly
2. **Verify PATH**: Make sure all tools are accessible
3. **AWS Permissions**: Confirm IAM user has required permissions
4. **Configuration**: Double-check terraform.tfvars has real values
5. **Clean Start**: Run `make clean` and try again

**Note**: This demo deploys real AWS infrastructure. Estimated cost: $2-5 for complete demo cycle with immediate cleanup.