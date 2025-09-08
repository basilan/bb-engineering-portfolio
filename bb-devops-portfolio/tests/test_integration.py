#!/usr/bin/env python3
"""
Integration tests for BB DevOps Portfolio - IaC Pipeline  
Tests the complete end-to-end functionality of the deployed infrastructure
"""

import pytest
import requests
import boto3
import json
import subprocess
import time
from pathlib import Path

class TestIntegration:
    """Integration tests for the complete infrastructure and configuration pipeline"""
    
    @pytest.fixture(scope="class")
    def terraform_outputs(self):
        """Get Terraform outputs for testing"""
        try:
            result = subprocess.run(
                ["terraform", "output", "-json"],
                cwd="../terraform",
                capture_output=True,
                text=True,
                check=True
            )
            return json.loads(result.stdout)
        except subprocess.CalledProcessError:
            pytest.skip("Terraform outputs not available - infrastructure may not be deployed")
    
    @pytest.fixture(scope="class")
    def web_server_url(self, terraform_outputs):
        """Get web server URL from Terraform outputs"""
        return terraform_outputs["web_server_url"]["value"]
    
    def test_web_server_accessibility(self, web_server_url, timeout=30):
        """Test that the web server is accessible and returns expected response"""
        # Wait for server to be ready (it may take time after Ansible configuration)
        for attempt in range(timeout):
            try:
                response = requests.get(web_server_url, timeout=10)
                if response.status_code == 200:
                    break
                time.sleep(1)
            except requests.exceptions.RequestException:
                if attempt == timeout - 1:
                    pytest.fail(f"Web server not accessible after {timeout} seconds")
                time.sleep(1)
        
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        assert "nginx" in response.headers.get("server", "").lower(), "NGINX server header not found"
    
    def test_web_server_content(self, web_server_url):
        """Test that the web server returns expected content"""
        response = requests.get(web_server_url, timeout=10)
        assert response.status_code == 200
        
        # Check for custom content from Ansible template
        content = response.text.lower()
        assert "bb-iac-demo" in content or "infrastructure" in content, "Custom content not found"
    
    def test_health_check_endpoint(self, web_server_url):
        """Test the health check endpoint created by Ansible"""
        health_url = f"{web_server_url.rstrip('/')}/health"
        response = requests.get(health_url, timeout=10)
        
        assert response.status_code == 200, f"Health check failed with status {response.status_code}"
        
        # Parse JSON response
        health_data = response.json()
        assert health_data["status"] == "healthy", "Health check status is not healthy"
        assert "timestamp" in health_data, "Health check missing timestamp"
        assert "version" in health_data, "Health check missing version"
    
    def test_security_headers(self, web_server_url):
        """Test that security headers are properly configured"""
        response = requests.get(web_server_url, timeout=10)
        
        # Check for security headers (these should be configured by Ansible)
        headers = response.headers
        
        # These are basic security checks
        assert "server" in headers, "Server header should be present"
        
        # Check that server doesn't reveal too much information
        server_header = headers.get("server", "").lower()
        assert "nginx" in server_header, "Should identify as nginx"
        # Ensure no version information is leaked (good security practice)
        assert not any(char.isdigit() for char in server_header), "Server header should not contain version numbers"
    
    def test_ssh_connectivity(self, terraform_outputs):
        """Test SSH connectivity to the server (using public key authentication)"""
        ssh_command = terraform_outputs["ssh_connection_command"]["value"]
        
        # Extract components from SSH command
        # Format: "ssh -i ~/.ssh/id_rsa ansible@<ip>"
        import shlex
        ssh_parts = shlex.split(ssh_command)
        
        if len(ssh_parts) >= 4:
            ssh_target = ssh_parts[-1]  # ansible@<ip>
            
            # Test SSH connection with a simple command
            test_command = ["ssh", "-i", "~/.ssh/id_rsa", "-o", "ConnectTimeout=10", 
                          "-o", "StrictHostKeyChecking=no", ssh_target, "echo 'SSH_TEST_OK'"]
            
            try:
                result = subprocess.run(test_command, capture_output=True, text=True, timeout=30)
                assert result.returncode == 0, f"SSH connection failed: {result.stderr}"
                assert "SSH_TEST_OK" in result.stdout, "SSH command execution failed"
            except subprocess.TimeoutExpired:
                pytest.skip("SSH connection timeout - may need manual key setup")
            except FileNotFoundError:
                pytest.skip("SSH client not available for testing")
    
    def test_infrastructure_components(self, terraform_outputs):
        """Test that all infrastructure components are properly created"""
        # Check that all expected outputs are present
        expected_outputs = [
            "vpc_id", "web_instance_id", "web_instance_public_ip",
            "s3_bucket_name", "security_group_id", "cloudwatch_log_group"
        ]
        
        for output in expected_outputs:
            assert output in terraform_outputs, f"Missing Terraform output: {output}"
            assert terraform_outputs[output]["value"], f"Empty Terraform output: {output}"
    
    def test_aws_s3_bucket_access(self, terraform_outputs):
        """Test that the S3 bucket is properly configured and accessible"""
        bucket_name = terraform_outputs["s3_bucket_name"]["value"]
        
        s3_client = boto3.client("s3")
        
        # Test bucket exists and is accessible
        try:
            response = s3_client.head_bucket(Bucket=bucket_name)
            assert response["ResponseMetadata"]["HTTPStatusCode"] == 200
        except s3_client.exceptions.NoSuchBucket:
            pytest.fail(f"S3 bucket {bucket_name} does not exist")
        
        # Test bucket encryption
        try:
            encryption = s3_client.get_bucket_encryption(Bucket=bucket_name)
            assert "Rules" in encryption["ServerSideEncryptionConfiguration"]
        except s3_client.exceptions.ClientError as e:
            if "ServerSideEncryptionConfigurationNotFoundError" in str(e):
                pytest.fail("S3 bucket encryption not configured")
            raise
        
        # Test public access is blocked
        try:
            public_access = s3_client.get_public_access_block(Bucket=bucket_name)
            access_config = public_access["PublicAccessBlockConfiguration"]
            assert access_config["BlockPublicAcls"] is True
            assert access_config["BlockPublicPolicy"] is True
            assert access_config["IgnorePublicAcls"] is True  
            assert access_config["RestrictPublicBuckets"] is True
        except s3_client.exceptions.ClientError:
            pytest.fail("S3 bucket public access block not configured")
    
    def test_cloudwatch_logging(self, terraform_outputs):
        """Test that CloudWatch logging is properly configured"""
        log_group_name = terraform_outputs["cloudwatch_log_group"]["value"]
        
        cloudwatch_client = boto3.client("logs")
        
        # Test log group exists
        try:
            response = cloudwatch_client.describe_log_groups(
                logGroupNamePrefix=log_group_name
            )
            log_groups = response["logGroups"]
            assert len(log_groups) > 0, f"Log group {log_group_name} not found"
            
            # Check retention policy
            log_group = next((lg for lg in log_groups if lg["logGroupName"] == log_group_name), None)
            assert log_group is not None, f"Log group {log_group_name} not found in response"
            assert log_group.get("retentionInDays", 0) > 0, "Log retention not configured"
            
        except cloudwatch_client.exceptions.ClientError:
            pytest.fail(f"Error accessing CloudWatch log group {log_group_name}")
    
    def test_security_configuration(self, web_server_url):
        """Test security configuration of the web server"""
        # Test that non-HTTP ports are not accessible
        import socket
        from urllib.parse import urlparse
        
        parsed_url = urlparse(web_server_url)
        host = parsed_url.hostname
        
        # Test that common insecure ports are blocked
        insecure_ports = [21, 23, 135, 139, 445, 1433, 3389]
        
        for port in insecure_ports:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((host, port))
            sock.close()
            
            # Connection should be refused (port closed/filtered)
            assert result != 0, f"Insecure port {port} is accessible and should be blocked"
    
    def test_performance_baseline(self, web_server_url):
        """Test basic performance characteristics"""
        # Test response time
        start_time = time.time()
        response = requests.get(web_server_url, timeout=30)
        response_time = time.time() - start_time
        
        assert response.status_code == 200
        assert response_time < 5.0, f"Response time too slow: {response_time:.2f}s"
        
        # Test concurrent requests (basic load test)
        import concurrent.futures
        
        def make_request():
            return requests.get(web_server_url, timeout=10)
        
        # Test 5 concurrent requests
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(make_request) for _ in range(5)]
            results = [future.result() for future in concurrent.futures.as_completed(futures)]
        
        # All requests should succeed
        for result in results:
            assert result.status_code == 200, "Concurrent request failed"

# Unhappy path tests
class TestIntegrationFailures:
    """Tests for error handling and failure scenarios"""
    
    def test_nonexistent_endpoint(self, terraform_outputs):
        """Test that nonexistent endpoints return appropriate errors"""
        web_server_url = terraform_outputs["web_server_url"]["value"]
        nonexistent_url = f"{web_server_url.rstrip('/')}/this-does-not-exist"
        
        response = requests.get(nonexistent_url, timeout=10)
        assert response.status_code == 404, f"Expected 404, got {response.status_code}"
    
    def test_malformed_requests(self, terraform_outputs):
        """Test handling of malformed requests"""
        web_server_url = terraform_outputs["web_server_url"]["value"]
        
        # Test with invalid HTTP method (if server properly configured, should return 405)
        try:
            response = requests.request("INVALID", web_server_url, timeout=10)
            # Most servers will reject this, but let's check it doesn't crash
            assert response.status_code in [400, 405, 501], "Server should reject invalid HTTP methods"
        except requests.exceptions.RequestException:
            # This is also acceptable - connection rejected
            pass

if __name__ == "__main__":
    pytest.main([__file__, "-v"])