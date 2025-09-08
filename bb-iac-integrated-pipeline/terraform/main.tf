terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "bb-iac-integrated-pipeline"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "brian-boelsterli"
      Purpose     = "enterprise-devops-demo"
    }
  }
}

# Generate random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create VPC for isolated networking
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "bb-iac-vpc-${random_string.suffix.result}"
  }
}

# Internet Gateway for public access
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "bb-iac-igw-${random_string.suffix.result}"
  }
}

# Public subnet for web server
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "bb-iac-public-subnet-${random_string.suffix.result}"
    Type = "public"
  }
}

# Route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "bb-iac-public-rt-${random_string.suffix.result}"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security group for web server
resource "aws_security_group" "web" {
  name        = "bb-iac-web-sg-${random_string.suffix.result}"
  description = "Security group for web server"
  vpc_id      = aws_vpc.main.id
  
  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }
  
  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }
  
  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }
  
  # Outbound access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
  
  tags = {
    Name = "bb-iac-web-sg-${random_string.suffix.result}"
  }
}

# Key pair for SSH access
resource "aws_key_pair" "deployer" {
  key_name   = "bb-iac-key-${random_string.suffix.result}"
  public_key = var.ssh_public_key
  
  tags = {
    Name = "bb-iac-deployer-key-${random_string.suffix.result}"
  }
}

# EC2 instance for web server
resource "aws_instance" "web" {
  ami                     = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = aws_subnet.public.id
  
  # Wait for instance to be ready for Ansible
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y python3 python3-pip
    # Create ansible user for configuration management
    useradd -m -s /bin/bash ansible
    mkdir -p /home/ansible/.ssh
    echo "${var.ssh_public_key}" >> /home/ansible/.ssh/authorized_keys
    chown -R ansible:ansible /home/ansible/.ssh
    chmod 700 /home/ansible/.ssh
    chmod 600 /home/ansible/.ssh/authorized_keys
    echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
  EOF
  
  tags = {
    Name        = "bb-iac-web-${random_string.suffix.result}"
    Environment = var.environment
    Role        = "webserver"
    AnsibleGroup = "web"
  }
}

# S3 bucket for storing configuration and logs
resource "aws_s3_bucket" "config" {
  bucket = "bb-iac-config-${formatdate("YYYYMMDD", timestamp())}-${random_string.suffix.result}"
  
  tags = {
    Name        = "bb-iac-config-bucket-${random_string.suffix.result}"
    Purpose     = "configuration-storage"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "config" {
  bucket = aws_s3_bucket.config.id
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket = aws_s3_bucket.config.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch Log Group for monitoring
resource "aws_cloudwatch_log_group" "web_logs" {
  name              = "/aws/ec2/bb-iac-web-${random_string.suffix.result}"
  retention_in_days = 7
  
  tags = {
    Name        = "bb-iac-web-logs-${random_string.suffix.result}"
    Environment = var.environment
    Purpose     = "web-server-logging"
  }
}

# Budget alert for cost control
resource "aws_budgets_budget" "demo_budget" {
  name         = "bb-iac-demo-budget-${random_string.suffix.result}"
  budget_type  = "COST"
  limit_amount = "50"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  cost_filters = {
    Tag = {
      Key    = "Project"
      Values = ["bb-iac-integrated-pipeline"]
    }
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
  }
}