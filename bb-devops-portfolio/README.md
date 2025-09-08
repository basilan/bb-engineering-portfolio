# 🚀 BB DevOps Portfolio - DevOps Reference Implementation

**Part of the BB Engineering Portfolio - Enterprise DevOps Automation**

## 🚀 Quick Start (5 Minutes)

**Complete DevOps automation: Infrastructure → Configuration → Testing → Cleanup**

```bash
# 1. Clone and navigate
git clone <repo-url>
cd bb-devops-portfolio

# 2. One-command setup  
make setup
# Creates real terraform.tfvars with your SSH key

# 3. Edit email (REQUIRED)
# Edit terraform/terraform.tfvars - replace REPLACE-WITH-YOUR-EMAIL

# 4. Test everything works (no AWS deployment)
make steel-thread
# Should show: ✅ All tools detected, ✅ All validations pass

# 5. Full demo with real AWS infrastructure (~$2-5, auto-cleanup)
make demo
# Complete audit trail: Environment → Infrastructure → Configuration → Testing → Cleanup
```

## 📋 Prerequisites

**Required Tools:**
- **AWS CLI** configured (`aws configure`) with appropriate permissions
- **Terraform** >= 1.5 installed
- **Ansible** >= 2.9 installed  
- **SSH Key** at `~/.ssh/id_rsa.pub` (generate with: `ssh-keygen -t rsa -b 4096`)
- **Python 3.11+** with pip (boto3, pytest, requests installed automatically)

**AWS Permissions Required:**
- EC2 (create/delete instances, security groups)
- VPC (create/delete networks, subnets, gateways)
- S3 (create/delete buckets)
- CloudWatch (create/delete log groups, metrics)
- Budgets (create/delete budget alerts)

## 🎯 What This Demonstrates

**Pattern**: Complete Infrastructure as Code automation pipeline integrating GitHub Actions, Terraform, Ansible, and AWS.

**Steel-Thread Implementation**: Single EC2 instance with enterprise-grade security hardening, monitoring, and web interface demonstrating the complete automation lifecycle.

**Business Impact**: 
- **80% reduction** in deployment time (hours → minutes)
- **100% elimination** of configuration drift
- **Automated security compliance** with CIS benchmarks
- **Complete audit trails** for enterprise requirements

## 🛠️ Available Commands

```bash
make help         # Show all available targets
make setup        # Initialize environment and dependencies
make steel-thread # Validate everything without AWS deployment
make demo         # Full deployment → configuration → testing → cleanup
make clean        # Clean up temporary files
make destroy      # Emergency infrastructure cleanup
```

## 🏗️ Architecture Overview

**Technology Stack**: AWS + Terraform + Ansible + GitHub Actions + pytest

**Infrastructure Created**:
- VPC with public subnet and security groups
- EC2 instance (t3.micro) with Ubuntu 22.04
- S3 bucket for logs and artifacts
- CloudWatch monitoring and budget controls

**Security & Compliance**:
- CIS security benchmark hardening
- UFW firewall + Fail2Ban protection  
- HTTPS with security headers
- Encrypted storage and transit

## 📚 Documentation

- **[Architecture Details](docs/ARCHITECTURE.md)** - Detailed system design and component integration
- **[Implementation Guide](docs/IMPLEMENTATION.md)** - Step-by-step development process and technical decisions
- **[Security Analysis](docs/SECURITY.md)** - Complete security controls and compliance details
- **[Value Analysis](docs/VALUE.md)** - Business impact, ROI calculations, and enterprise benefits

## 🔍 Validation Results

**Steel-Thread Status**: ✅ All validations pass
- Infrastructure tests: 8/8 passing
- Configuration tests: 13/13 passing  
- Security scans: All compliant
- Templates: Professional web interfaces ready

**Cost**: ~$2-5 for full demo (auto-cleanup prevents ongoing charges)

**Time**: 5 minutes setup → 2 minutes validation → 8 minutes full demo

---

**Portfolio Context**: This is **DevOps Reference Implementation #1** - part of the broader BB Engineering Portfolio demonstrating enterprise-grade automation patterns for infrastructure, security, and operations.