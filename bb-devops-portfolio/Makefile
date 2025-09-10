.PHONY: help setup check-setup steel-thread teardown

# Default target
help: ## Show this help message
	@echo "BB DevOps Portfolio - DevOps Reference Implementation"
	@echo "===================================================="
	@echo ""
	@echo "Core targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo ""
	@echo "Usage flow:"
	@echo "  make setup → make check-setup → make steel-thread → [prompted] → make teardown"
	@echo ""
	@echo "⚠️  IMPORTANT: steel-thread deploys AWS resources that cost money"
	@echo "    Always run teardown after steel-thread to avoid charges"

setup: ## Initialize environment with automated tool installation
	@echo "🚀 BB DevOps Portfolio - Automated Environment Setup"
	@echo "==============================================="
	@echo ""
	@echo "🔧 Phase 1: Tool Detection and Installation"
	@./scripts/auto-install-tools.sh || { echo "❌ Tool installation failed - see output above"; exit 1; }
	@echo ""
	@echo "🔑 Phase 2: AWS Configuration Validation"
	@AWS_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "AWS_PATH=" | cut -d'"' -f2) && \
		$$AWS_CMD sts get-caller-identity >/dev/null 2>&1 || { \
			echo "⚠️  AWS credentials not configured"; \
			echo "Please run: aws configure"; \
			echo "Or set environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"; \
			exit 1; \
		}
	@echo "✅ AWS credentials validated"
	@echo ""
	@echo "🐍 Phase 3: Python Dependencies"
	@python3 -c "import boto3, pytest, requests, moto" 2>/dev/null || pip3 install --user boto3 pytest requests moto 2>/dev/null || pip3 install --break-system-packages boto3 pytest requests moto
	@echo "✅ Python dependencies installed"
	@echo ""
	@echo "🔐 Phase 4: SSH Key Validation"
	@test -f ~/.ssh/id_rsa.pub || { \
			echo "⚠️  SSH key not found - generating new key..."; \
			read -p "Generate new SSH key? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1; \
			ssh-keygen -t rsa -b 4096 -C "bb-devops-portfolio@$$(whoami)" -f ~/.ssh/id_rsa -N ""; \
			echo "✅ SSH key generated"; \
		} || echo "✅ SSH key found"
	@echo ""
	@echo "📝 Phase 5: Terraform Configuration"
	@cd terraform && \
		(test -f terraform.tfvars && echo "📝 terraform.tfvars exists, skipping creation") || \
		(echo "📝 Creating terraform.tfvars with real values..." && \
		echo "# Real configuration - created by make setup $$(date)" > terraform.tfvars && \
		echo "aws_region = \"us-east-1\"" >> terraform.tfvars && \
		echo "environment = \"dev\"" >> terraform.tfvars && \
		echo "instance_type = \"t3.micro\"" >> terraform.tfvars && \
		echo "" >> terraform.tfvars && \
		echo "# Your actual SSH public key (auto-generated)" >> terraform.tfvars && \
		printf 'ssh_public_key = "%s"\n' "$$(cat ~/.ssh/id_rsa.pub)" >> terraform.tfvars && \
		echo "" >> terraform.tfvars && \
		echo "# IMPORTANT: Replace with your real email for AWS budget alerts" >> terraform.tfvars && \
		echo "notification_email = \"REPLACE-WITH-YOUR-EMAIL@domain.com\"" >> terraform.tfvars && \
		echo "" >> terraform.tfvars && \
		echo "# Optional: Restrict SSH access to your IP (default allows all)" >> terraform.tfvars && \
		echo "# allowed_cidr_blocks = [\"YOUR.IP.ADDRESS.HERE/32\"]" >> terraform.tfvars)
	@TERRAFORM_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "TERRAFORM_PATH=" | cut -d'"' -f2) && \
		cd terraform && $$TERRAFORM_CMD init
	@echo "✅ Terraform configuration initialized"
	@echo ""
	@echo "⚠️  IMPORTANT: Edit terraform/terraform.tfvars and replace REPLACE-WITH-YOUR-EMAIL@domain.com with your real email"
	@echo "✅ Environment setup complete - ready for steel-thread execution"


check-setup: ## Check all configurations without AWS deployment
	@echo "🔍 Quick validation without AWS deployment"
	@echo "═══════════════════════════════════════════"
	@./scripts/find-tools.sh >/dev/null 2>&1 && echo "✅ CLI tools detected" || { echo "❌ Missing tools - see README.md"; exit 1; }
	@cd terraform && terraform validate >/dev/null 2>&1 && echo "✅ Terraform valid" || { echo "❌ Terraform failed - see README.md"; exit 1; }
	@ANSIBLE_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "ANSIBLE_PLAYBOOK_PATH=" | cut -d'"' -f2) && $$ANSIBLE_CMD --syntax-check ansible/site.yml >/dev/null 2>&1 && echo "✅ Ansible valid" || { echo "❌ Ansible failed - see README.md"; exit 1; }
	@echo "   → Running infrastructure tests..." && python3 -m pytest tests/test_infrastructure.py -q && echo "✅ Infrastructure tests pass" || { echo "❌ Infrastructure tests failed"; exit 1; }
	@echo "   → Running configuration tests..." && python3 -m pytest tests/test_configuration.py -q && echo "✅ Configuration tests pass" || { echo "❌ Configuration tests failed"; exit 1; }
	@echo ""
	@echo "🎯 All checks passed - ready for steel-thread demo"

steel-thread: ## Complete end-to-end demo with timestamped logging: deploy → configure → test → show → destroy
	@source ./scripts/steel-thread-logger.sh && initialize_logging
	@echo "🎯 STEEL-THREAD DEMONSTRATION WITH ENHANCED LOGGING"
	@echo "===================================================="
	@echo "Complete DevOps automation: GitHub Actions → Terraform → Ansible → Testing → Cleanup"
	@echo "Execution logs will be saved to: logs/steel-thread-$$(date +%Y%m%d_%H%M%S).log"
	@echo ""
	@read -p "Deploy live AWS infrastructure for demo? (y/N): " confirm && [ "$$confirm" = "y" ] || { source ./scripts/steel-thread-logger.sh && finalize_logging "cancelled"; exit 1; }
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
		cd terraform && $$TERRAFORM_CMD plan -var-file=terraform.tfvars -compact-warnings | grep -E '^(data\.|#|Plan:|Terraform|~|Apply|Error:|Warning:)'
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
	@echo "⚠️  CRITICAL: AWS resources are still running and costing money!"
	@echo ""
	@read -p "Run teardown to destroy all AWS resources now? (y/N): " cleanup && \
		if [ "$$cleanup" = "y" ]; then \
			$(MAKE) teardown; \
		else \
			echo ""; \
			echo "⚠️  WARNING: Resources still deployed - run 'make teardown' when done"; \
			echo "   → Current charges: EC2 t3.micro (~$$0.0104/hour)"; \
			echo "   → Estimated cost if left running: ~$$0.25/day"; \
			echo ""; \
		fi

teardown: ## Destroy all AWS resources and clean local files
	@echo "🧹 ENTRY: Complete Teardown"
	@echo "   → Infrastructure destruction: Destroying all AWS resources (VPC, EC2, S3, etc.)"
	@TERRAFORM_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "TERRAFORM_PATH=" | cut -d'"' -f2) && \
		cd terraform && $$TERRAFORM_CMD destroy -var-file=terraform.tfvars -auto-approve
	@echo "   → Cleanup verification: Confirming all resources destroyed"
	@TERRAFORM_CMD=$$(./scripts/find-tools.sh 2>/dev/null | grep "TERRAFORM_PATH=" | cut -d'"' -f2) && \
		cd terraform && $$TERRAFORM_CMD state list | wc -l | awk '{if($$1==0) print "   → AWS resources: ✅ ALL DESTROYED"; else print "   → AWS resources: ⚠️  SOME REMAIN"}'
	@echo "   → Local file cleanup: Removing temporary files"
	@rm -f terraform/tfplan terraform/.terraform.lock.hcl
	@rm -rf terraform/.terraform/ tests/__pycache__/ ansible/retry/
	@rm -f ansible/inventory/hosts.yml.bak
	@echo "   → Local files: ✅ CLEANED"
	@echo "🧹 EXIT: Teardown complete"
	@echo ""
	@echo "💰 Cost verification: AWS resources should show $0.00 charges going forward"
	@echo "🏆 Ready for next steel-thread run!"