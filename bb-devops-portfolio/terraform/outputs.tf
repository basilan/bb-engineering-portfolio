output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "web_instance_id" {
  description = "ID of the web server instance"
  value       = aws_instance.web.id
}

output "web_instance_public_ip" {
  description = "Public IP address of the web server"
  value       = aws_instance.web.public_ip
}

output "web_instance_private_ip" {
  description = "Private IP address of the web server"
  value       = aws_instance.web.private_ip
}

output "web_instance_public_dns" {
  description = "Public DNS name of the web server"
  value       = aws_instance.web.public_dns
}

output "security_group_id" {
  description = "ID of the web server security group"
  value       = aws_security_group.web.id
}

output "ssh_key_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.deployer.key_name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for configuration storage"
  value       = aws_s3_bucket.config.bucket
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for web server logs"
  value       = aws_cloudwatch_log_group.web_logs.name
}

# Ansible inventory information
output "ansible_inventory" {
  description = "Ansible inventory information for configuration management"
  value = {
    web_servers = {
      hosts = {
        web1 = {
          ansible_host                 = aws_instance.web.public_ip
          ansible_user                 = "ansible"
          ansible_ssh_private_key_file = "~/.ssh/id_rsa"
          instance_id                  = aws_instance.web.id
          environment                  = var.environment
        }
      }
    }
  }
}

# Web server URL for testing
output "web_server_url" {
  description = "URL to access the web server (after Ansible configuration)"
  value       = "http://${aws_instance.web.public_ip}"
}

# SSH connection command
output "ssh_connection_command" {
  description = "Command to SSH into the web server"
  value       = "ssh -i ~/.ssh/id_rsa ansible@${aws_instance.web.public_ip}"
}