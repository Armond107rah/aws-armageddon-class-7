
# Tokyo application IAM foundation.
# Reuse the tested Lab 2 IAM module.

module "iam" {
  source = "../../../lab-2/infrastructure/modules/iam"

  project_name = var.project_name
}

# Grant the application access only to the
# database configuration and secret it needs.
# This policy is created when the Tokyo database is enabled.

resource "aws_iam_role_policy" "tokyo_db_config_read" {
  count = var.enable_tokyo_database ? 1 : 0

  name = "${var.project_name}-db-config-read"
  role = module.iam.role_name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadTokyoDatabaseParameters"
        Effect = "Allow"

        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]

        Resource = module.parameters[0].parameter_arns
      },
      {
        Sid    = "ReadTokyoManagedDatabaseSecret"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = module.database[0].master_secret_arn
      }
    ]
  })
}
