
# ==========================================
# DATABASE MODULE OUTPUTS
# ==========================================

output "rds_endpoint" {
  description = "Private RDS database hostname"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "Database connection port"
  value       = aws_db_instance.mysql.port
}

output "rds_security_group_id" {
  description = "Database security group ID"
  value       = aws_security_group.rds_sg.id
}

output "db_instance_identifier" {
  description = "RDS database identifier"
  value       = aws_db_instance.mysql.identifier
}

output "master_secret_arn" {
  description = "ARN of the RDS-managed master secret"
  value       = aws_db_instance.mysql.master_user_secret[0].secret_arn
}

output "db_name" {
  description = "Application database name"
  value       = aws_db_instance.mysql.db_name
}

output "db_parameter_group_name" {
  description = "MySQL TLS enforcement parameter group"
  value       = aws_db_parameter_group.enforced_tls.name
}
