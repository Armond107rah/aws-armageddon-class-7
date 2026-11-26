# -------------------------------------------
# Tokyo application monitoring
# -------------------------------------------

# Application log group. The instance sends
# /var/log/rdsapp.log here through the
# CloudWatch agent.

resource "aws_cloudwatch_log_group" "tokyo_app" {
  count = var.enable_tokyo_monitoring ? 1 : 0

  name              = "/aws/ec2/${var.project_name}-tokyo-app"
  retention_in_days = 7

  tags = {
    Name    = "${var.project_name}-app-logs"
    Purpose = "tokyo-application-logs"
  }
}

# Allow the application role to publish logs
# to this group and connection-error metrics
# in the Lab 3 namespace only.

resource "aws_iam_role_policy" "tokyo_observability" {
  count = var.enable_tokyo_monitoring ? 1 : 0

  name = "${var.project_name}-observability"
  role = module.iam.role_name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "WriteTokyoApplicationLogs"
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]

        Resource = [
          aws_cloudwatch_log_group.tokyo_app[0].arn,
          "${aws_cloudwatch_log_group.tokyo_app[0].arn}:*"
        ]
      },
      {
        Sid    = "PublishTokyoDatabaseMetrics"
        Effect = "Allow"

        Action = [
          "cloudwatch:PutMetricData"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "Lab3/TokyoDatabase"
          }
        }
      }
    ]
  })
}
