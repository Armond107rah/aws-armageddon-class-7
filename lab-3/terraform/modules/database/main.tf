
# ==========================================
# AWS ARMAGEDDON LAB 3
# TOKYO RDS DATABASE MODULE
# ==========================================

# 1. MySQL parameter group
# Require encrypted connections to RDS.

resource "aws_db_parameter_group" "enforced_tls" {
  name_prefix = "${var.project_name}-mysql-tls-"

  family      = "mysql8.4"
  description = "Require encrypted MySQL connections"

  parameter {
    name         = "require_secure_transport"
    value        = "ON"
    apply_method = "immediate"
  }

  tags = {
    Name = "${var.project_name}-mysql-tls"
  }
}


# 2. Database subnet group
# The RDS database uses private subnets.

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnets"
  }
}


# 3. Database security group
# No public ingress rules.

resource "aws_security_group" "rds_sg" {
  name_prefix = "${var.project_name}-rds-"
  description = "Private MySQL database access"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}


# 4. MySQL access rule
# Only approved application security groups
# may access the database on TCP 3306.

resource "aws_vpc_security_group_ingress_rule" "mysql" {
  security_group_id = aws_security_group.rds_sg.id

  from_port   = 3306
  to_port     = 3306
  ip_protocol = "tcp"

  referenced_security_group_id = var.ec2_security_group_id

  description = "MySQL access from approved application"
}


# 5. Private Amazon RDS MySQL instance
# Authoritative medical-data region: Tokyo.

resource "aws_db_instance" "mysql" {
  identifier = "${var.project_name}-mysql"

  engine         = "mysql"
  engine_version = "8.4"
  instance_class = "db.t3.micro"

  # Database storage
  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  # Application database
  db_name  = var.db_name
  username = var.db_username

  # AWS manages the master database password.
  manage_master_user_password = true

  # Require secure MySQL transport.
  parameter_group_name = aws_db_parameter_group.enforced_tls.name

  # Place RDS in private subnets.
  db_subnet_group_name = aws_db_subnet_group.main.name

  # Restrict database network access.
  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]

  publicly_accessible = false
  multi_az            = false

  # Short backup retention for the lab.
  backup_retention_period = 1

  # Disposable lab settings.
  # Reassess before any production deployment.
  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name        = "${var.project_name}-mysql"
    Environment = "learning"
    DataRegion  = "tokyo"
  }
}
