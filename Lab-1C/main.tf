module "networking" {
  source = "./modules/networking"

  project_name = "lab-1c-learning"
  vpc_cidr     = "10.234.0.0/16"

  public_subnet_cidrs = [
    "10.234.0.0/24",
    "10.234.16.0/24"
  ]

  private_subnet_cidrs = [
    "10.234.128.0/24",
    "10.234.144.0/24"
  ]
  # NAT gateway setting
  enable_nat_gateway = false
}

module "iam" {
  source = "./modules/iam"

  project_name = "lab-1c-learning"
}

module "compute" {
  source = "./modules/compute"

  project_name          = "lab-1c-learning"
  vpc_id                = module.networking.vpc_id
  public_subnet_id      = module.networking.public_subnet_ids[0]
  instance_profile_name = module.iam.instance_profile_name

  allowed_http_cidr = var.allowed_http_cidr
}

module "database" {
  source = "./modules/database"

  project_name = "lab-1c-learning"

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  ec2_security_group_id = module.compute.security_group_id

  db_name     = "labdb"
  db_username = "labadmin"
}

module "parameters" {
  source = "./modules/parameters"

  project_name = "lab-1c-learning"

  db_endpoint       = module.database.rds_endpoint
  db_port           = module.database.rds_port
  db_name           = module.database.db_name
  master_secret_arn = module.database.master_secret_arn

  parameter_path = "/lab/db"
}

resource "aws_iam_role_policy" "ec2_db_config_read" {
  name = "lab-1c-learning-db-config-read"
  role = module.iam.role_name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadDatabaseParameters"
        Effect = "Allow"

        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]

        Resource = module.parameters.parameter_arns
      },
      {
        Sid    = "ReadDatabaseSecret"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = module.database.master_secret_arn
      }
    ]
  })
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name = "lab-1c-learning"

  db_instance_identifier = module.database.db_instance_identifier

  notification_email = var.notification_email
}

resource "aws_iam_role_policy" "ec2_cloudwatch_logs" {
  name = "lab-1c-learning-cloudwatch-write"
  role = module.iam.role_name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]

        Resource = [
          module.monitoring.app_log_group_arn,
          "${module.monitoring.app_log_group_arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_db_metric_write" {
  name = "lab-1c-learning-db-metric-write"
  role = module.iam.role_name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "cloudwatch:PutMetricData"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "Lab1C/Database"
          }
        }
      }
    ]
  })
}

