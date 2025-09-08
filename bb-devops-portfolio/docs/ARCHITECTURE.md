# 🏗️ Architecture Documentation

**BB DevOps Portfolio - Detailed System Design**

## 📊 Technology Stack Analysis

### Individual Stack Purpose & Typical Usage

| Technology | Primary Purpose | Typical Enterprise Usage | Role in This Implementation |
|------------|----------------|-------------------------|---------------------------|
| **AWS** | Cloud Infrastructure Provider | Hosting applications, data storage, compute resources | Provides VPC, EC2, S3, CloudWatch, Security Groups |
| **Terraform** | Infrastructure as Code (IaC) | Provisioning cloud resources declaratively | Defines and creates all AWS infrastructure components |
| **Ansible** | Configuration Management | Server setup, software installation, compliance | Hardens security, installs Nginx, configures monitoring |
| **GitHub Actions** | CI/CD Pipeline Automation | Build, test, deploy workflows | Orchestrates entire pipeline from validation to deployment |
| **pytest** | Testing Framework | Infrastructure and application testing | Validates deployment success and configuration compliance |

### Technology Synergies When Combined

**Traditional Challenges Solved:**
- **Manual Error-Prone Processes**: Human mistakes in server configuration
- **Configuration Drift**: Servers gradually diverging from intended state  
- **Security Gaps**: Inconsistent security hardening across environments
- **Lack of Auditability**: No clear record of infrastructure changes
- **Slow Deployment Cycles**: Hours/days to provision and configure infrastructure

**Combined Solution Benefits:**
- **Declarative Infrastructure**: Infrastructure defined in code, version controlled
- **Automated Compliance**: Security hardening applied consistently every time
- **Immutable Deployments**: Infrastructure recreated identically across environments
- **Complete Automation**: Zero-touch deployment from code commit to running application
- **Full Observability**: Every change tracked, tested, and monitored

## 🎯 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        GITHUB REPOSITORY                        │
├─────────────────────────────────────────────────────────────────┤
│  📁 .github/workflows/    📁 terraform/    📁 ansible/         │
│     ├── ci-cd-pipeline.yml   ├── main.tf       ├── site.yml     │
│     └── [GitHub Actions]     ├── variables.tf  ├── roles/       │
│                               └── outputs.tf    └── inventory/  │
└─────────────┬───────────────────────────────────────────────────┘
              │ git push
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GITHUB ACTIONS RUNNER                      │
├─────────────────────────────────────────────────────────────────┤
│  🔍 VALIDATE     🔧 PLAN        🚀 DEPLOY       ✅ TEST        │
│  ├─Terraform    ├─terraform    ├─terraform     ├─HTTP Tests    │
│  │ fmt/validate │ plan         │ apply          │─SSH Tests     │
│  ├─Ansible      ├─Security     ├─ansible       │─Security      │
│  │ syntax-check │ Scan (tfsec) │ playbook      │ Validation    │
│  └─Security     └─Cost         └─Integration   └─Performance   │
│    Scanning       Analysis        Testing         Baseline     │
└─────────────┬───────────┬───────────┬───────────────┬───────────┘
              │           │           │               │
              │           ▼           ▼               │
              │    ┌─────────────────────────────┐   │
              │    │         AWS CLOUD           │   │
              │    ├─────────────────────────────┤   │
              │    │  🏗️ INFRASTRUCTURE LAYER   │   │
              │    │  ├── VPC (10.0.0.0/16)     │   │
              │    │  ├── Public Subnet         │   │
              │    │  ├── Internet Gateway      │   │
              │    │  ├── Route Tables          │   │
              │    │  ├── Security Groups       │   │
              │    │  ├── S3 Bucket (encrypted) │   │
              │    │  └── Budget Controls       │   │
              │    │                            │   │
              │    │  💻 COMPUTE LAYER          │   │
              │    │  ├── EC2 Instance          │   │
              │    │  │   ├── Ubuntu 22.04      │   │
              │    │  │   ├── t3.micro          │   │
              │    │  │   └── SSH Key Access    │   │
              │    │  │                         │   │
              │    │  📊 MONITORING LAYER       │   │
              │    │  ├── CloudWatch Logs       │   │
              │    │  ├── CloudWatch Metrics    │   │
              │    │  └── Custom Dashboards     │   │
              │    │                            │   │
              │    │  🔒 SECURITY LAYER         │   │
              │    │  ├── UFW Firewall         │   │
              │    │  ├── Fail2Ban Protection  │   │
              │    │  ├── CIS Benchmarks       │   │
              │    │  └── Security Headers     │   │
              │    └─────────────────────────────┘   │
              │                                       │
              │  ┌─────────────────────────────────┐ │
              └──│         MONITORING              │─┘
                 ├─────────────────────────────────┤
                 │  📊 Health Checks              │
                 │  📊 Performance Metrics        │
                 │  📊 Security Compliance        │
                 │  📊 Cost Tracking              │
                 │  📊 Audit Logs                 │
                 └─────────────────────────────────┘
```

## 🗂️ Component Deep Dive

### Infrastructure Components (Terraform)

**VPC and Networking**:
- **VPC**: 10.0.0.0/16 CIDR block providing isolated network space
- **Public Subnet**: 10.0.1.0/24 for internet-accessible resources
- **Internet Gateway**: Enables internet connectivity
- **Route Tables**: Direct traffic between subnet and internet gateway
- **Security Groups**: Stateful firewall rules (SSH:22, HTTP:80, HTTPS:443)

**Compute Resources**:
- **EC2 Instance**: t3.micro (1 vCPU, 1GB RAM) - AWS free tier eligible
- **AMI**: Ubuntu 22.04 LTS with automatic security updates
- **Storage**: 8GB GP3 EBS volume with encryption at rest
- **SSH Access**: Key-based authentication with configurable IP restrictions

**Storage and Monitoring**:
- **S3 Bucket**: Encrypted storage for logs and artifacts with versioning
- **CloudWatch Log Groups**: Centralized log collection and retention
- **CloudWatch Dashboards**: Real-time monitoring and alerting
- **Budget Controls**: Cost monitoring with email alerts

### Configuration Management (Ansible)

**Security Hardening Role**:
- **UFW Firewall**: Default deny with selective port opening
- **Fail2Ban**: Intrusion prevention system for SSH brute force protection  
- **CIS Benchmarks**: Security configuration baseline compliance
- **System Updates**: Automatic security patch management
- **SSH Hardening**: Key-only auth, disabled root login, rate limiting

**Web Server Role**:
- **Nginx Installation**: Latest stable version with security modules
- **SSL Configuration**: TLS 1.3 with strong cipher suites
- **Security Headers**: HSTS, CSP, X-Frame-Options, X-Content-Type-Options
- **Static Content**: Professional dashboard and monitoring interfaces
- **Log Configuration**: Structured logging to CloudWatch

**Monitoring Role**:
- **CloudWatch Agent**: System and application metrics collection
- **Log Rotation**: Automated log management and cleanup
- **Health Checks**: HTTP endpoint monitoring and alerting
- **Performance Baselines**: CPU, memory, disk, and network monitoring

### Testing Framework (pytest)

**Infrastructure Tests**:
- Terraform configuration validation
- Resource dependency verification  
- Security group rule compliance
- Tag and naming convention compliance
- Cost optimization checks

**Configuration Tests**:
- Ansible playbook syntax validation
- Role dependency verification
- Template rendering validation
- Handler notification testing
- Security hardening verification

**Integration Tests**:
- HTTP endpoint availability
- SSL certificate validation
- Security header verification
- CloudWatch log ingestion
- Performance threshold validation

## 🔄 Data Flow

### Deployment Flow

1. **Trigger**: Git push or manual workflow dispatch
2. **Validation**: Terraform and Ansible syntax checking
3. **Security Scanning**: Infrastructure security analysis
4. **Planning**: Terraform plan generation and review
5. **Provisioning**: AWS resource creation via Terraform
6. **Configuration**: Server hardening and application setup via Ansible
7. **Testing**: Comprehensive validation of deployed infrastructure
8. **Monitoring**: Health checks and performance baseline establishment
9. **Notification**: Deployment success confirmation with access URLs

### Runtime Data Flow

1. **User Request**: HTTP/HTTPS traffic to public IP
2. **Network Layer**: Security group filtering and UFW firewall processing
3. **Web Server**: Nginx request processing with security headers
4. **Application Layer**: Static content delivery with monitoring integration
5. **Logging**: Request logging to local files and CloudWatch
6. **Monitoring**: Metrics collection and dashboard updates
7. **Alerting**: Threshold-based notifications for anomalies

## ⚙️ Configuration Management

### Environment Variables

| Variable | Purpose | Default | Required |
|----------|---------|---------|----------|
| `aws_region` | AWS deployment region | us-east-1 | Yes |
| `environment` | Environment identifier | dev | Yes |
| `instance_type` | EC2 instance size | t3.micro | Yes |
| `ssh_public_key` | SSH access key | ~/.ssh/id_rsa.pub | Yes |
| `notification_email` | Alert destination | None | Yes |
| `allowed_cidr_blocks` | SSH IP restrictions | 0.0.0.0/0 | No |

### File Structure

```
bb-devops-portfolio/
├── terraform/              # Infrastructure as Code
│   ├── main.tf             # Core AWS resources
│   ├── variables.tf        # Input parameters
│   ├── outputs.tf          # Resource references
│   └── terraform.tfvars    # Environment-specific values
├── ansible/                # Configuration Management
│   ├── site.yml           # Main playbook
│   ├── inventory/         # Target host definitions
│   └── roles/             # Reusable configuration modules
│       ├── security/      # Hardening and compliance
│       ├── nginx/         # Web server setup
│       └── monitoring/    # Observability configuration
├── tests/                 # Validation Framework
│   ├── test_infrastructure.py  # Terraform validation
│   ├── test_configuration.py   # Ansible validation
│   └── test_integration.py     # End-to-end validation
└── scripts/               # Automation Utilities
    └── find-tools.sh      # Dependency detection
```

## 🔒 Security Architecture

### Defense in Depth

**Network Level**:
- VPC isolation with private subnets for sensitive resources
- Security groups with principle of least privilege
- Network ACLs for additional packet filtering

**Host Level**:
- OS hardening following CIS benchmarks
- Regular security updates and patch management
- File system encryption and access controls

**Application Level**:
- HTTPS enforcement with modern TLS protocols
- Security headers preventing common web attacks
- Input validation and output encoding

**Monitoring Level**:
- Real-time intrusion detection with Fail2Ban
- Log analysis for suspicious activity patterns
- Automated alerting for security violations

### Compliance Framework

**CIS Controls Implementation**:
- Inventory and Control of Enterprise Assets
- Inventory and Control of Software Assets  
- Continuous Vulnerability Management
- Controlled Use of Administrative Privileges
- Secure Configuration for Hardware and Software
- Maintenance, Monitoring, and Analysis of Audit Logs

**Audit Trail Components**:
- Infrastructure changes via Terraform state
- Configuration changes via Ansible logs
- Access logs via CloudWatch
- Security events via system logs
- Performance metrics via monitoring dashboards