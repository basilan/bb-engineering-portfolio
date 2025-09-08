variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^[a-z0-9]+\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "ssh_public_key" {
  description = "Public SSH key for EC2 access"
  type        = string

  validation {
    condition     = can(regex("^ssh-", var.ssh_public_key))
    error_message = "SSH public key must start with ssh- (ssh-rsa, ssh-ed25519, etc.)."
  }
}

variable "notification_email" {
  description = "Email address for budget notifications"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "Notification email must be a valid email address."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access. SECURITY: Restrict to your IP for production use."
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: This allows SSH from anywhere. Change to your IP: ["YOUR.IP.HERE/32"]

  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All allowed_cidr_blocks must be valid CIDR blocks. Example: ['192.168.1.100/32']"
  }
}