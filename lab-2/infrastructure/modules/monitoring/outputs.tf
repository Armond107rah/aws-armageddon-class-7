
output "sns_topic_arn" {
  description = "SNS topic ARN for database incidents"
  value       = aws_sns_topic.db_incidents.arn
}

output "alarm_name" {
  description = "CloudWatch database connection alarm"
  value       = aws_cloudwatch_metric_alarm.db_connection_errors.alarm_name
}

output "app_log_group_name" {
  description = "EC2 application CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.name
}

output "app_log_group_arn" {
  description = "ARN of the application log group"
  value       = aws_cloudwatch_log_group.app.arn
}
