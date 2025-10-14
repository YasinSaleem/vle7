# Simple Terraform Outputs
# These outputs provide important information after deployment

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.study_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.study_server.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.study_sg.id
}

output "instance_id" {
  description = "Instance ID of the server"
  value       = aws_instance.study_server.id
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance (if key_name provided)"
  value       = var.key_name != "" ? "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_instance.study_server.public_ip}" : "No SSH key configured"
}

output "web_url" {
  description = "URL to access web services on the instance"
  value       = "http://${aws_instance.study_server.public_ip}"
}

# Simple setup - no complex cloud services
# Perfect for learning Terraform basics