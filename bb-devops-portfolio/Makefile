.PHONY: help setup check steel-thread clean destroy

# Default target
help: ## Show this help message
	@echo "BB DevOps Portfolio - DevOps Reference Implementation"
	@echo "===================================================="
	@echo ""
	@echo "Essential targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo ""
	@echo "🔄 Steel-Thread Demo Flow:"
	@echo "┌─────────────────────────────────────────────────────────────────────────────┐"
	@echo "│                          COMPLETE DEMO LIFECYCLE                           │"
	@echo "├─────────────────────────────────────────────────────────────────────────────┤"
	@echo "│  1️⃣  make setup     → Initialize tools + create terraform.tfvars + SSH key │"
	@echo "│     ├── Tool detection (terraform, ansible, aws, python)                  │"
	@echo "│     ├── AWS credentials validation                                         │"
	@echo "│     ├── SSH key generation (if missing)                                   │"
	@echo "│     └── Terraform initialization                                           │"
	@echo "│                                                                             │"
	@echo "│  2️⃣  make check     → Quick validation without AWS deployment              │"
	@echo "│     ├── CLI tools detection                                                │"
	@echo "│     ├── Terraform syntax validation                                        │"
	@echo "│     ├── Ansible playbook syntax check                                      │"
	@echo "│     └── Test suite execution (infrastructure + configuration)             │"
	@echo "│                                                                             │"
	@echo "│  3️⃣  make steel-thread → Complete end-to-end demo (THE BIG KAHUNA)       │"
	@echo "│     ├── 🔍 Environment validation                                          │"
	@echo "│     ├── 🚀 Infrastructure provisioning (Terraform → AWS)                  │"
	@echo "│     │   └── Creates: VPC, EC2, S3, CloudWatch, Security Groups           │"
	@echo "│     ├── ⚙️  Configuration management (Ansible)                            │"
	@echo "│     │   ├── Security hardening (CIS benchmarks, UFW, Fail2Ban)            │"
	@echo "│     │   ├── Web server setup (Nginx + SSL + security headers)             │"
	@echo "│     │   └── Monitoring setup (CloudWatch agent + log rotation)            │"
	@echo "│     ├── ✅ Integration validation (HTTP tests + security headers)         │"
	@echo "│     ├── 🌐 Live demonstration (show running infrastructure)               │"
	@echo "│     └── 🧹 Resource cleanup (destroy all AWS resources)                   │"
	@echo "│                                                                             │"
	@echo "│  4️⃣  make clean    → Clean up local temporary files                       │"
	@echo "│     └── Removes: terraform cache, test cache, ansible backup files       │"
	@echo "│                                                                             │"
	@echo "│  5️⃣  make destroy  → Emergency cleanup (if steel-thread didn't finish)   │"
	@echo "│     └── Force destroy all AWS resources                                    │"
	@echo "└─────────────────────────────────────────────────────────────────────────────┘"
	@echo ""
	@echo "🔗 Target Dependencies:"
	@echo "┌─────────────────────────────────────────────────────────────────────────────┐"
	@echo "│                            DEPENDENCY FLOW                                 │"
	@echo "├─────────────────────────────────────────────────────────────────────────────┤"
	@echo "│                                                                             │"
	@echo "│  setup (prerequisite for all)                                              │"
	@echo "│    │                                                                       │"
	@echo "│    ├──→ check (validates setup worked)                                     │"
	@echo "│    │                                                                       │"
	@echo "│    └──→ steel-thread (requires setup + includes check validation)         │"
	@echo "│              │                                                             │"
	@echo "│              ├──→ [internal] terraform plan                               │"
	@echo "│              ├──→ [internal] terraform apply                              │"
	@echo "│              ├──→ [internal] ansible security role                       │"
	@echo "│              ├──→ [internal] ansible nginx role                          │"
	@echo "│              ├──→ [internal] ansible monitoring role                     │"
	@echo "│              ├──→ [internal] integration tests                           │"
	@echo "│              └──→ [internal] terraform destroy (cleanup)                 │"
	@echo "│                                                                             │"
	@echo "│  clean (independent - removes local files)                                 │"
	@echo "│                                                                             │"
	@echo "│  destroy (emergency only - removes AWS resources)                          │"
	@echo "│                                                                             │"
	@echo "└─────────────────────────────────────────────────────────────────────────────┘"
	@echo ""
	@echo "⚡ Quick Start:"
	@echo "  make setup && make check && make steel-thread"
	@echo ""
	@echo "🔧 Development Cycle:"
	@echo "  make setup    (first time only)"
	@echo "  make check    (fast validation)"
	@echo "  make clean    (cleanup temp files)"
	@echo ""
	@echo "📋 Prerequisites in README.md - run if setup fails"

setup: ## Initialize environment and install dependencies
	@echo "🔧 Setting up environment..."
	@echo "📋 Detecting and validating CLI tools..."
	@./scripts/find-tools.sh >/dev/null 2>&1 || { echo "❌ Missing required tools. Run: ./scripts/find-tools.sh for details or see README.md"; exit 1; }
	@echo "✅ All CLI tools detected"
	@AWS_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "AWS_PATH=" | cut -d'"' -f2) && \
		$$AWS_CMD sts get-caller-identity >/dev/null 2>&1 || { echo "❌ AWS credentials not configured. Run: aws configure or see README.md"; exit 1; }
	@python3 -c "import boto3, pytest, requests" 2>/dev/null || pip3 install boto3 pytest requests
	@test -f ~/.ssh/id_rsa.pub || { echo "❌ SSH key not found. Generate with: ssh-keygen -t rsa -b 4096 or see README.md"; exit 1; }
	@echo "🔑 Setting up real terraform configuration..."
	@cd terraform && \
		(test -f terraform.tfvars && echo "📝 terraform.tfvars exists, skipping creation") || \
		(echo "📝 Creating terraform.tfvars with real values..." && \
		echo "# Real configuration - created by make setup" > terraform.tfvars && \
		echo "aws_region = \"us-east-1\"" >> terraform.tfvars && \
		echo "environment = \"dev\"" >> terraform.tfvars && \
		echo "instance_type = \"t3.micro\"" >> terraform.tfvars && \
		echo "" >> terraform.tfvars && \
		echo "# Your actual SSH public key" >> terraform.tfvars && \
		printf 'ssh_public_key = "%s"\n' "$$(cat ~/.ssh/id_rsa.pub)" >> terraform.tfvars && \
		echo "" >> terraform.tfvars && \
		echo "# IMPORTANT: Replace with your real email for AWS budget alerts" >> terraform.tfvars && \
		echo "notification_email = \"REPLACE-WITH-YOUR-EMAIL@domain.com\"" >> terraform.tfvars && \
		echo "" >> terraform.tfvars && \
		echo "# Optional: Restrict SSH access to your IP (default allows all)" >> terraform.tfvars && \
		echo "# allowed_cidr_blocks = [\"YOUR.IP.ADDRESS.HERE/32\"]" >> terraform.tfvars)
	@TERRAFORM_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "TERRAFORM_PATH=" | cut -d'"' -f2) && \
		cd terraform && $$TERRAFORM_CMD init
	@echo ""
	@echo "⚠️  IMPORTANT: Edit terraform/terraform.tfvars and replace REPLACE-WITH-YOUR-EMAIL@domain.com with your real email"
	@echo "✅ Environment setup complete"


check: ## Check all configurations without AWS deployment
	@echo "🔍 Quick validation without AWS deployment"
	@echo "═══════════════════════════════════════════"
	@./scripts/find-tools.sh >/dev/null 2>&1 && echo "✅ CLI tools detected" || { echo "❌ Missing tools - see README.md"; exit 1; }
	@cd terraform && terraform validate >/dev/null 2>&1 && echo "✅ Terraform valid" || { echo "❌ Terraform failed - see README.md"; exit 1; }
	@ANSIBLE_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "ANSIBLE_PLAYBOOK_PATH=" | cut -d'"' -f2) && $$ANSIBLE_CMD --syntax-check ansible/site.yml >/dev/null 2>&1 && echo "✅ Ansible valid" || { echo "❌ Ansible failed - see README.md"; exit 1; }
	@python3 -m pytest tests/test_infrastructure.py -q >/dev/null 2>&1 && echo "✅ Infrastructure tests pass" || { echo "❌ Tests failed - see README.md"; exit 1; }
	@python3 -m pytest tests/test_configuration.py -q >/dev/null 2>&1 && echo "✅ Configuration tests pass" || { echo "❌ Tests failed - see README.md"; exit 1; }
	@echo ""
	@echo "🎯 All checks passed - ready for steel-thread demo"

steel-thread: ## Complete end-to-end demo: deploy → configure → test → show → destroy
	@echo "🎯 STEEL-THREAD DEMONSTRATION"
	@echo "============================================="
	@echo "Complete DevOps automation: GitHub Actions → Terraform → Ansible → Testing → Cleanup"
	@echo ""
	@read -p "Deploy live AWS infrastructure for demo? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo ""
	@echo "🔍 ENTRY: Environment Validation"
	@echo "   → Detecting CLI tools and validating configuration"
	@TERRAFORM_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "TERRAFORM_PATH=" | cut -d'"' -f2) && \
		AWS_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "AWS_PATH=" | cut -d'"' -f2) && \
		cd terraform && $$TERRAFORM_CMD validate >/dev/null 2>&1 && echo "   → Terraform configuration: ✅ VALID" || echo "   → Terraform configuration: ❌ FAILED"
	@AWS_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "AWS_PATH=" | cut -d'"' -f2) && \
		$$AWS_CMD sts get-caller-identity >/dev/null 2>&1 && echo "   → AWS credentials: ✅ AUTHENTICATED" || echo "   → AWS credentials: ❌ FAILED"
	@echo "🔍 EXIT: Environment ready for deployment"
	@echo ""
	@echo "🚀 ENTRY: Infrastructure Provisioning (Terraform → AWS)"
	@echo "   → Planning deployment: VPC, EC2, S3, Security Groups, CloudWatch"
	@TERRAFORM_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "TERRAFORM_PATH=" | cut -d'"' -f2) && \
		cd terraform && $$TERRAFORM_CMD plan -var-file=terraform.tfvars -compact-warnings
	@echo "   → Provisioning infrastructure: Creating 14 AWS resources"
	@TERRAFORM_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "TERRAFORM_PATH=" | cut -d'"' -f2) && \
		cd terraform && $$TERRAFORM_CMD apply -var-file=terraform.tfvars -auto-approve
	@TERRAFORM_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "TERRAFORM_PATH=" | cut -d'"' -f2) && \
		cd terraform && WEB_IP=$$($$TERRAFORM_CMD output -raw web_instance_public_ip) && echo "   → Infrastructure provisioned: ✅ COMPLETE (http://$$WEB_IP)"
	@echo "🚀 EXIT: Infrastructure ready for configuration"
	@echo ""
	@echo "   → Instance boot delay: Waiting 60 seconds for EC2 readiness"
	@sleep 60
	@echo ""
	@echo "⚙️ ENTRY: Configuration Management (Ansible)"
	@echo "   → Updating Ansible inventory with actual EC2 IP address"
	@TERRAFORM_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "TERRAFORM_PATH=" | cut -d'"' -f2) && \
		cd terraform && WEB_IP=$$($$TERRAFORM_CMD output -raw web_instance_public_ip) && \
		cd ../ansible && \
		sed -i.bak "s/ansible_host: 127.0.0.1/ansible_host: $$WEB_IP/" inventory/hosts.yml && \
		sed -i.bak "s/placeholder:/web1:/" inventory/hosts.yml
	@echo "   → Security hardening: Applying CIS benchmarks, UFW firewall, Fail2Ban protection"
	@ANSIBLE_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "ANSIBLE_PLAYBOOK_PATH=" | cut -d'"' -f2) && \
		cd ansible && $$ANSIBLE_CMD -i inventory/hosts.yml site.yml --limit web --tags security
	@echo "   → Security hardening: ✅ APPLIED"
	@echo "   → Web server setup: Installing Nginx with SSL and security headers"
	@ANSIBLE_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "ANSIBLE_PLAYBOOK_PATH=" | cut -d'"' -f2) && \
		cd ansible && $$ANSIBLE_CMD -i inventory/hosts.yml site.yml --limit web --tags nginx
	@echo "   → Web server setup: ✅ CONFIGURED"
	@echo "   → Monitoring setup: Configuring CloudWatch agent and log rotation"
	@ANSIBLE_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "ANSIBLE_PLAYBOOK_PATH=" | cut -d'"' -f2) && \
		cd ansible && $$ANSIBLE_CMD -i inventory/hosts.yml site.yml --limit web --tags monitoring
	@echo "   → Monitoring setup: ✅ ACTIVE"
	@echo "⚙️ EXIT: Configuration management complete"
	@echo ""
	@echo "✅ ENTRY: Integration Validation"
	@echo "   → HTTP endpoint testing: Validating web server response and availability"
	@python3 -m pytest tests/test_integration.py::TestIntegration::test_web_server_accessibility -v
	@echo "   → Security header validation: Verifying HTTPS, HSTS, CSP headers"
	@python3 -m pytest tests/test_integration.py::TestIntegration::test_security_headers -v
	@echo "   → Health check validation: Testing monitoring and status endpoints"
	@python3 -m pytest tests/test_integration.py::TestIntegration::test_health_check_endpoint -v
	@echo "✅ EXIT: System validation complete"
	@echo ""
	@echo "🌐 ENTRY: Live Demonstration"
	@cd terraform && WEB_IP=$$(terraform output -raw web_instance_public_ip) && echo "   → Professional dashboard: http://$$WEB_IP" && echo "   → Monitoring interface: http://$$WEB_IP/monitoring.html" && echo "   → Health check endpoint:" && curl -s "http://$$WEB_IP/health"
	@echo "🌐 EXIT: Demo complete - infrastructure running"
	@echo ""
	@echo "🎉 STEEL-THREAD COMPLETE!"
	@echo "Real infrastructure accessible at URLs above ↑"
	@echo ""
	@echo "Press ENTER to destroy all resources and cleanup..."
	@read
	@echo ""
	@echo "🧹 ENTRY: Resource Cleanup"
	@echo "   → Infrastructure destruction: Destroying all AWS resources (VPC, EC2, S3, etc.)"
	@TERRAFORM_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "TERRAFORM_PATH=" | cut -d'"' -f2) && \
		cd terraform && $$TERRAFORM_CMD destroy -var-file=terraform.tfvars -auto-approve
	@echo "   → Cleanup verification: Confirming all resources destroyed"
	@TERRAFORM_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "TERRAFORM_PATH=" | cut -d'"' -f2) && \
		cd terraform && $$TERRAFORM_CMD state list | wc -l | awk '{if($$1==0) print "   → Resource cleanup: ✅ ALL DESTROYED"; else print "   → Resource cleanup: ⚠️  SOME REMAIN"}'
	@echo "🧹 EXIT: Cleanup complete"
	@echo ""
	@echo "🏆 Steel-thread demo complete - ready for next run!"

clean: ## Clean up temporary files and state
	@echo "🧹 Cleaning up temporary files..."
	@rm -f terraform/tfplan
	@rm -f terraform/.terraform.lock.hcl
	@rm -rf terraform/.terraform/
	@rm -rf tests/__pycache__/
	@rm -rf ansible/retry/
	@rm -f ansible/inventory/hosts.yml.bak
	@echo "✅ Cleanup complete"

destroy: ## Destroy all infrastructure (WARNING: irreversible)
	@echo "⚠️  WARNING: This will destroy all infrastructure!"
	@echo "This includes EC2, VPC, S3, CloudWatch logs, and all associated resources"
	@echo ""
	@read -p "Are you sure you want to destroy everything? Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] || { echo "❌ Destruction cancelled"; exit 1; }
	@TERRAFORM_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "TERRAFORM_PATH=" | cut -d'"' -f2) && \
		cd terraform && $$TERRAFORM_CMD destroy -auto-approve || { echo "❌ FAILED - see README.md for setup"; exit 1; }
	@echo "✅ Infrastructure destroyed"