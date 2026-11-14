
# Store the database hostname
resource "aws_ssm_parameter" "db_endpoint" {
  name        = "${var.parameter_path}/endpoint"
  description = "RDS database hostname"
  type        = "String"
  value       = var.db_endpoint

  tags = {
    Project = var.project_name
  }
}

# Store the database port
resource "aws_ssm_parameter" "db_port" {
  name        = "${var.parameter_path}/port"
  description = "RDS database port"
  type        = "String"
  value       = tostring(var.db_port)

  tags = {
    Project = var.project_name
  }
}

# Store the database name
resource "aws_ssm_parameter" "db_name" {
  name        = "${var.parameter_path}/name"
  description = "Application database name"
  type        = "String"
  value       = var.db_name

  tags = {
    Project = var.project_name
  }
}

# Store a reference to the RDS-managed credential secret
resource "aws_ssm_parameter" "master_secret_arn" {
  name        = "${var.parameter_path}/master-secret-arn"
  description = "Reference to the RDS-managed secret"
  type        = "String"
  value       = var.master_secret_arn

  tags = {
    Project = var.project_name
  }
}
