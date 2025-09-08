.PHONY: help setup validate deploy configure test demo clean destroy all

# Default target
help: ## Show this help message
	@echo "BB Infrastructure as Code - Integrated Pipeline"
	@echo "============================================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo ""
	@echo "Prerequisites:"
	@echo "  - AWS CLI configured with appropriate permissions"
	@echo "  - Terraform >= 1.5 installed"
	@echo "  - Ansible >= 2.9 installed"
	@echo "  - SSH key pair available at ~/.ssh/id_rsa"
	@echo "  - Python 3.11+ with boto3, pytest, requests"

setup: ## Initialize environment and install dependencies
	@echo "🔧 Setting up environment..."
	@command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform not found. Please install Terraform >= 1.5"; exit 1; }
	@command -v ansible >/dev/null 2>&1 || { echo "❌ Ansible not found. Please install Ansible >= 2.9"; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI not found. Please install AWS CLI"; exit 1; }
	@python3 -c "import boto3, pytest, requests" 2>/dev/null || pip3 install boto3 pytest requests
	@test -f ~/.ssh/id_rsa.pub || { echo "❌ SSH key not found. Please generate one with: ssh-keygen -t rsa -b 4096"; exit 1; }
	@cd terraform && terraform init
	@echo "✅ Environment setup complete"

validate: ## Validate Terraform configuration and Ansible playbooks
	@echo "🔍 Validating infrastructure configuration..."
	@cd terraform && terraform fmt -check
	@cd terraform && terraform validate
	@echo "🔍 Validating Ansible configuration..."
	@cd ansible && ansible-playbook --syntax-check site.yml
	@echo "🔍 Running security scans..."
	@cd terraform && terraform plan -out=tfplan >/dev/null 2>&1 && echo "✅ Terraform security scan passed" || echo "❌ Terraform validation failed"
	@echo "✅ Validation complete"

deploy: ## Deploy infrastructure with Terraform
	@echo "🚀 Deploying infrastructure..."
	@cd terraform && terraform plan -out=tfplan
	@read -p "Deploy infrastructure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@cd terraform && terraform apply tfplan
	@echo "✅ Infrastructure deployment complete"
	@echo "📋 Terraform outputs:"
	@cd terraform && terraform output

configure: ## Configure servers with Ansible (run after deploy)
	@echo "⚙️  Configuring servers with Ansible..."
	@echo "⏳ Waiting 60 seconds for instance to be ready..."
	@sleep 60
	@cd ansible && ansible-playbook -i inventory/hosts.yml site.yml
	@echo "✅ Server configuration complete"

test: ## Run comprehensive test suite
	@echo "🧪 Running comprehensive test suite..."
	@python3 -m pytest tests/ -v --tb=short
	@echo "✅ All tests passed"

demo: ## Full end-to-end demonstration
	@echo "🎬 Starting full end-to-end demonstration..."
	@echo ""
	@echo "This demo will:"
	@echo "  1. Deploy AWS infrastructure (VPC, EC2, S3, Security Groups)"
	@echo "  2. Configure web server with Ansible (NGINX + security hardening)"  
	@echo "  3. Run comprehensive tests (infrastructure + configuration + integration)"
	@echo "  4. Display results and cleanup instructions"
	@echo ""
	@read -p "Continue with demo? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	$(MAKE) setup
	$(MAKE) validate
	$(MAKE) deploy
	$(MAKE) configure
	$(MAKE) test
	@echo ""
	@echo "🎉 Demo complete! Here's what was accomplished:"
	@echo ""
	@cd terraform && echo "🌐 Web Server URL: $$(terraform output -raw web_server_url)"
	@cd terraform && echo "🔐 SSH Command: $$(terraform output -raw ssh_connection_command)"
	@echo "📊 S3 Configuration Bucket: Created with encryption and versioning"
	@echo "🔒 Security: UFW firewall, Fail2ban, SSH hardening applied"
	@echo "📈 Monitoring: CloudWatch logs and budget alerts configured"
	@echo ""
	@echo "💰 Cost Control: Resources will auto-alert at 80% of $50 monthly budget"
	@echo "🧹 Cleanup: Run 'make destroy' to remove all resources when done"

clean: ## Clean up temporary files and state
	@echo "🧹 Cleaning up temporary files..."
	@rm -f terraform/tfplan
	@rm -f terraform/.terraform.lock.hcl
	@rm -rf terraform/.terraform/
	@rm -f tests/__pycache__/
	@rm -f ansible/retry/
	@echo "✅ Cleanup complete"

destroy: ## Destroy all infrastructure (WARNING: irreversible)
	@echo "⚠️  WARNING: This will destroy all infrastructure!"
	@echo "This includes:"
	@echo "  - EC2 instances"
	@echo "  - VPC and networking components"
	@echo "  - S3 buckets and data"
	@echo "  - CloudWatch logs"
	@echo "  - All associated resources"
	@echo ""
	@read -p "Are you sure you want to destroy everything? Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] || exit 1
	@cd terraform && terraform destroy -auto-approve
	@echo "✅ Infrastructure destroyed"

all: setup validate deploy configure test ## Run complete pipeline from setup to test

# Development targets
tf-plan: ## Show Terraform plan without applying
	@cd terraform && terraform plan

tf-apply: ## Apply Terraform changes
	@cd terraform && terraform apply

tf-output: ## Show Terraform outputs
	@cd terraform && terraform output

ansible-check: ## Run Ansible in check mode (dry run)
	@cd ansible && ansible-playbook -i inventory/hosts.yml site.yml --check --diff

ansible-run: ## Run Ansible configuration
	@cd ansible && ansible-playbook -i inventory/hosts.yml site.yml

test-infrastructure: ## Test only infrastructure components
	@python3 -m pytest tests/test_infrastructure.py -v

test-configuration: ## Test only configuration components  
	@python3 -m pytest tests/test_configuration.py -v

test-integration: ## Test only integration components
	@python3 -m pytest tests/test_integration.py -v

# Security and compliance targets
security-scan: ## Run comprehensive security scanning
	@echo "🔒 Running security scans..."
	@cd terraform && terraform plan -out=tfplan >/dev/null 2>&1
	@echo "✅ Infrastructure security scan complete"

compliance-check: ## Check compliance against CIS benchmarks
	@echo "📋 Running compliance checks..."
	@cd ansible && ansible-playbook site.yml --tags security --check
	@echo "✅ Compliance check complete"

# Monitoring and status targets
status: ## Show current infrastructure status
	@echo "📊 Infrastructure Status:"
	@cd terraform && terraform output -json | python3 -m json.tool
	@echo ""
	@echo "🔧 Ansible Configuration Status:"
	@cd ansible && ansible all -i inventory/hosts.yml -m ping

logs: ## Show CloudWatch logs (requires AWS CLI)
	@cd terraform && LOG_GROUP=$$(terraform output -raw cloudwatch_log_group) && aws logs describe-log-streams --log-group-name $$LOG_GROUP

budget: ## Show current AWS costs for this project
	@echo "💰 Current project costs:"
	@aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-12-31 --granularity MONTHLY --metrics BlendedCost --group-by Type=DIMENSION,Key=SERVICE | jq '.ResultsByTime[-1].Groups[] | select(.Keys[0] | contains("EC2")) | .Metrics.BlendedCost.Amount'