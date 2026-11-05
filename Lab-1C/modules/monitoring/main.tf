
# Create an SNS topic for database incidents
resource "aws_sns_topic" "db_incidents" {
  name = "${var.project_name}-db-incidents"

  tags = {
    Project = var.project_name
  }
}

# Subscribe an email address to the SNS topic
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.db_incidents.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# Monitor application-reported DB connection errors
resource "aws_cloudwatch_metric_alarm" "db_connection_errors" {
  alarm_name        = "${var.project_name}-db-connection-errors"
  alarm_description = "Alert when DB connection errors reach 3 in 5 minutes"

  namespace   = "Lab1C/Database"
  metric_name = "DBConnectionErrors"

  statistic = "Sum"
  period    = 300

  threshold           = 3
  comparison_operator = "GreaterThanOrEqualToThreshold"

  evaluation_periods = 1

  treat_missing_data = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions = [
    aws_sns_topic.db_incidents.arn
  ]

  tags = {
    Project = var.project_name
  }
}

# Create a log group for EC2 application logs
resource "aws_cloudwatch_log_group" "app" {
  name = "/aws/ec2/${var.project_name}-rds-app"

  retention_in_days = 7

  tags = {
    Name    = "${var.project_name}-app-logs"
    Project = var.project_name
  }
}
