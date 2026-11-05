output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (us-east-1a/1b/1c)."
  value = [
    aws_subnet.public["us-east-1a"].id,
    aws_subnet.public["us-east-1b"].id,
    aws_subnet.public["us-east-1c"].id,
  ]
}

output "private_subnet_ids" {
  description = "Private subnet IDs (us-east-1a/1b/1c)."
  value = [
    aws_subnet.private["us-east-1a"].id,
    aws_subnet.private["us-east-1b"].id,
    aws_subnet.private["us-east-1c"].id,
  ]
}

output "ec2_instance_id" {
  description = "EC2 instance ID for the app host."
  value       = aws_instance.app.id
}

output "ec2_public_ip" {
  description = "EC2 public IP for the app host."
  value       = aws_instance.app.public_ip
}

output "rds_endpoint" {
  description = "RDS endpoint hostname."
  value       = aws_db_instance.mysql.address
}

output "secret_arn" {
  description = "Secrets Manager secret ARN for DB credentials/config."
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "parameter_names" {
  description = "SSM parameter names for DB config."
  value = [
    aws_ssm_parameter.db_endpoint.name,
    aws_ssm_parameter.db_port.name,
    aws_ssm_parameter.db_name.name,
  ]
}

output "log_group_name" {
  description = "CloudWatch Logs log group name for the app."
  value       = aws_cloudwatch_log_group.app.name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for notifications."
  value       = aws_sns_topic.alerts.arn
}

output "db_failure_alarm_name" {
  description = "CloudWatch alarm name for DB connection failures."
  value       = aws_cloudwatch_metric_alarm.db_connection_failure.alarm_name
}
