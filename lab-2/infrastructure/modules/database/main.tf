
# Database subnet group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnets"
  }
}

# Security group for the database
resource "aws_security_group" "rds_sg" {
  name_prefix = "${var.project_name}-rds-"
  description = "Private MySQL database access"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# Only allow the EC2 security group to access MySQL
resource "aws_vpc_security_group_ingress_rule" "mysql" {
  security_group_id = aws_security_group.rds_sg.id

  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.ec2_security_group_id
}

# Private MySQL database
resource "aws_db_instance" "mysql" {
  identifier = "${var.project_name}-mysql"

  engine         = "mysql"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 0
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = {
    Name = "${var.project_name}-mysql"
  }
}
