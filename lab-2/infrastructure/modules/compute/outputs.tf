
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web_server.id
}

output "public_ip" {
  description = "Public IP address of the web server"
  value       = aws_instance.web_server.public_ip
}

output "private_ip" {
  description = "Private IP address of the web server"
  value       = aws_instance.web_server.private_ip
}

output "security_group_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.web_sg.id
}
