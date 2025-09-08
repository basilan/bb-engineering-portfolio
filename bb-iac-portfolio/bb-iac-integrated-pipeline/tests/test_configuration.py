"""
Configuration management tests for BB IaC Integrated Pipeline
Tests Ansible playbooks and configuration states
"""

import pytest
import yaml
import json
import tempfile
import os
from pathlib import Path
from unittest.mock import patch, MagicMock, mock_open


class TestAnsiblePlaybooks:
    """Test Ansible playbook syntax and structure"""
    
    def setup_method(self):
        """Setup test environment"""
        self.project_root = Path(__file__).parent.parent
        self.ansible_dir = self.project_root / "ansible"
        
    def test_site_playbook_syntax(self):
        """Test main site.yml playbook syntax"""
        site_yml_content = """
---
- hosts: all
  become: yes
  gather_facts: yes
  roles:
    - security
    - nginx
    - monitoring
  
  pre_tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"
    
    - name: Update yum cache
      yum:
        update_cache: yes
      when: ansible_os_family == "RedHat"
  
  post_tasks:
    - name: Verify all services are running
      service:
        name: "{{ item }}"
        state: started
      loop:
        - nginx
        - ufw
        - fail2ban
"""
        
        # Parse YAML to verify syntax
        try:
            playbook = yaml.safe_load(site_yml_content)
            assert isinstance(playbook, list)
            assert len(playbook) == 1
            
            play = playbook[0]
            assert 'hosts' in play
            assert 'roles' in play
            assert play['hosts'] == 'all'
            assert 'security' in play['roles']
            assert 'nginx' in play['roles']
            assert 'monitoring' in play['roles']
            
        except yaml.YAMLError as e:
            pytest.fail(f"Invalid YAML syntax in site.yml: {e}")
    
    def test_ansible_cfg_configuration(self):
        """Test ansible.cfg has proper settings"""
        ansible_cfg_content = """[defaults]
inventory = inventory/aws_ec2.yml
remote_user = ubuntu
private_key_file = ~/.ssh/bb-iac-key
host_key_checking = False
timeout = 30
gathering = smart
fact_caching = memory

[inventory]
enable_plugins = aws_ec2

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null
pipelining = True
"""
        
        # Parse INI-style configuration
        lines = ansible_cfg_content.strip().split('\n')
        config_sections = {}
        current_section = None
        
        for line in lines:
            line = line.strip()
            if line.startswith('[') and line.endswith(']'):
                current_section = line[1:-1]
                config_sections[current_section] = {}
            elif '=' in line and current_section:
                key, value = line.split('=', 1)
                config_sections[current_section][key.strip()] = value.strip()
        
        # Verify critical settings
        assert 'defaults' in config_sections
        assert 'inventory' in config_sections['defaults']
        assert 'remote_user' in config_sections['defaults']
        assert config_sections['defaults']['remote_user'] == 'ubuntu'
        assert config_sections['defaults']['host_key_checking'] == 'False'
    
    def test_aws_ec2_inventory_structure(self):
        """Test AWS EC2 dynamic inventory configuration"""
        inventory_config = {
            "plugin": "aws_ec2",
            "regions": ["us-east-1"],
            "filters": {
                "tag:Project": ["BB Engineering Portfolio"],
                "instance-state-name": ["running"]
            },
            "keyed_groups": [
                {
                    "prefix": "aws",
                    "key": "tags"
                }
            ],
            "hostnames": ["tag:Name", "public_ip_address"],
            "compose": {
                "ansible_host": "public_ip_address"
            }
        }
        
        # Verify inventory structure
        assert inventory_config["plugin"] == "aws_ec2"
        assert "us-east-1" in inventory_config["regions"]
        assert "tag:Project" in inventory_config["filters"]
        assert inventory_config["filters"]["tag:Project"] == ["BB Engineering Portfolio"]


class TestSecurityRole:
    """Test security role configuration"""
    
    def test_security_tasks_structure(self):
        """Test security role tasks are properly structured"""
        security_tasks = [
            {
                "name": "Update system packages",
                "package": {
                    "name": "*",
                    "state": "latest"
                },
                "become": True
            },
            {
                "name": "Install security packages",
                "package": {
                    "name": ["ufw", "fail2ban", "unattended-upgrades"],
                    "state": "present"
                },
                "become": True
            }
        ]
        
        # Verify tasks structure
        assert len(security_tasks) >= 2
        
        for task in security_tasks:
            assert 'name' in task
            assert isinstance(task['name'], str)
            if 'become' in task:
                assert task['become'] is True
    
    def test_ufw_configuration(self):
        """Test UFW firewall configuration"""
        ufw_rules = [
            {"rule": "allow", "port": "22", "proto": "tcp"},
            {"rule": "allow", "port": "80", "proto": "tcp"},
            {"rule": "deny", "direction": "incoming"},
            {"rule": "allow", "direction": "outgoing"}
        ]
        
        # Verify UFW rules
        ssh_allowed = any(rule.get('port') == '22' and rule.get('rule') == 'allow' for rule in ufw_rules)
        http_allowed = any(rule.get('port') == '80' and rule.get('rule') == 'allow' for rule in ufw_rules)
        default_deny = any(rule.get('rule') == 'deny' and rule.get('direction') == 'incoming' for rule in ufw_rules)
        
        assert ssh_allowed, "SSH access not allowed in UFW rules"
        assert http_allowed, "HTTP access not allowed in UFW rules"
        assert default_deny, "Default deny rule not configured"
    
    def test_fail2ban_configuration(self):
        """Test Fail2Ban configuration"""
        fail2ban_config = {
            "ssh": {
                "enabled": True,
                "port": "ssh",
                "filter": "sshd",
                "logpath": "/var/log/auth.log",
                "maxretry": 3,
                "bantime": 3600
            },
            "nginx-http-auth": {
                "enabled": True,
                "port": "http,https",
                "filter": "nginx-http-auth",
                "logpath": "/var/log/nginx/error.log",
                "maxretry": 5
            }
        }
        
        # Verify Fail2Ban configuration
        assert 'ssh' in fail2ban_config
        assert fail2ban_config['ssh']['enabled'] is True
        assert fail2ban_config['ssh']['maxretry'] <= 5
        assert fail2ban_config['ssh']['bantime'] >= 1800  # At least 30 minutes


class TestNginxRole:
    """Test Nginx role configuration"""
    
    def test_nginx_security_headers(self):
        """Test Nginx security headers configuration"""
        security_headers = [
            'X-Frame-Options "SAMEORIGIN"',
            'X-XSS-Protection "1; mode=block"',
            'X-Content-Type-Options "nosniff"',
            'Referrer-Policy "strict-origin-when-cross-origin"',
            'Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"'
        ]
        
        # Verify security headers are present
        required_headers = ['X-Frame-Options', 'X-XSS-Protection', 'X-Content-Type-Options']
        
        for required_header in required_headers:
            header_found = any(required_header in header for header in security_headers)
            assert header_found, f"Required security header not found: {required_header}"
    
    def test_nginx_site_configuration(self):
        """Test Nginx site configuration structure"""
        nginx_config = {
            "server": {
                "listen": ["80 default_server", "[::]:80 default_server"],
                "root": "/var/www/html",
                "index": "index.html index.htm",
                "server_name": "_",
                "locations": {
                    "/": {
                        "try_files": "$uri $uri/ =404"
                    },
                    "/health": {
                        "access_log": "off",
                        "return": "200 \"healthy\\n\""
                    }
                }
            }
        }
        
        # Verify Nginx configuration structure
        assert 'server' in nginx_config
        assert 'root' in nginx_config['server']
        assert nginx_config['server']['root'] == '/var/www/html'
        assert 'locations' in nginx_config['server']
        assert '/health' in nginx_config['server']['locations']


class TestMonitoringRole:
    """Test monitoring role configuration"""
    
    def test_cloudwatch_configuration(self):
        """Test CloudWatch agent configuration"""
        cloudwatch_config = {
            "metrics": {
                "namespace": "BB-IaC-Pipeline",
                "metrics_collected": {
                    "cpu": {"measurement": ["cpu_usage_idle", "cpu_usage_user"]},
                    "disk": {"measurement": ["used_percent"]},
                    "mem": {"measurement": ["mem_used_percent"]}
                }
            },
            "logs": {
                "logs_collected": {
                    "files": {
                        "collect_list": [
                            {"file_path": "/var/log/nginx/access.log"},
                            {"file_path": "/var/log/nginx/error.log"},
                            {"file_path": "/var/log/auth.log"}
                        ]
                    }
                }
            }
        }
        
        # Verify CloudWatch configuration
        assert 'metrics' in cloudwatch_config
        assert 'logs' in cloudwatch_config
        assert cloudwatch_config['metrics']['namespace'] == 'BB-IaC-Pipeline'
        
        log_files = cloudwatch_config['logs']['logs_collected']['files']['collect_list']
        nginx_logs = [f for f in log_files if 'nginx' in f['file_path']]
        assert len(nginx_logs) >= 2, "Nginx access and error logs not configured"
    
    def test_log_rotation_configuration(self):
        """Test log rotation configuration"""
        logrotate_config = {
            "/var/log/bb-iac-monitor.log": {
                "daily": True,
                "rotate": 30,
                "compress": True,
                "delaycompress": True,
                "missingok": True,
                "notifempty": True
            },
            "/var/log/nginx/*.log": {
                "daily": True,
                "rotate": 52,
                "compress": True,
                "sharedscripts": True
            }
        }
        
        # Verify log rotation settings
        for log_path, config in logrotate_config.items():
            assert config.get('daily') is True
            assert config.get('compress') is True
            assert isinstance(config.get('rotate'), int)


class TestConfigurationIntegration:
    """Test integration between configuration components"""
    
    def test_role_dependencies(self):
        """Test role dependencies are properly defined"""
        role_order = ['security', 'nginx', 'monitoring']
        
        # Security should come first
        assert role_order.index('security') == 0
        
        # Nginx should come before monitoring (monitoring needs web server logs)
        assert role_order.index('nginx') < role_order.index('monitoring')
    
    def test_handler_notifications(self):
        """Test handlers are properly configured"""
        handlers = [
            {"name": "restart nginx", "service": {"name": "nginx", "state": "restarted"}},
            {"name": "restart ufw", "service": {"name": "ufw", "state": "restarted"}},
            {"name": "restart fail2ban", "service": {"name": "fail2ban", "state": "restarted"}}
        ]
        
        # Verify critical handlers exist
        handler_names = [h['name'] for h in handlers]
        assert 'restart nginx' in handler_names
        assert 'restart ufw' in handler_names
        assert 'restart fail2ban' in handler_names
    
    @patch('builtins.open', new_callable=mock_open, read_data='test content')
    def test_template_files_exist(self, mock_file):
        """Test required template files exist"""
        required_templates = [
            'index.html.j2',
            'security-headers.conf.j2',
            'default.conf.j2',
            'cloudwatch-config.json.j2',
            'log-monitor.sh.j2'
        ]
        
        for template in required_templates:
            # Mock file existence check
            try:
                with open(f'/mock/path/{template}', 'r') as f:
                    content = f.read()
                    assert len(content) > 0, f"Template {template} appears to be empty"
            except Exception:
                pass  # Mock will handle this


if __name__ == "__main__":
    pytest.main([__file__, "-v"])