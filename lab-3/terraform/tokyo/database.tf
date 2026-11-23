
# Security group reserved for approved Tokyo application instances.
#
# No public inbound rule is defined here.

resource "aws_security_group" "tokyo_app" {
  name_prefix = "${var.project_name}-app-"
  description = "Tokyo application security boundary"
  vpc_id      = module.networking.vpc_id

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

# Authoritative database - Tokyo only.
# Existing Lab 2 database module provides:
# - Private MySQL RDS
# - Encrypted storage
# - AWS-managed master credentials
# - Security-group-based MySQL access
#
# Disabled by default until deployment.

module "database" {
  count = var.enable_tokyo_database ? 1 : 0

  source = "../../../lab-2/infrastructure/modules/database"

  project_name = var.project_name

  vpc_id = module.networking.vpc_id

  private_subnet_ids = module.networking.private_subnet_ids

  ec2_security_group_id = aws_security_group.tokyo_app.id

  db_name     = var.db_name
  db_username = var.db_username
}

# Permit future application instances using
# the Tokyo app security group to connect
# to the private database on MySQL port 3306.

resource "aws_vpc_security_group_egress_rule" "tokyo_mysql" {
  count = var.enable_tokyo_database ? 1 : 0

  security_group_id = aws_security_group.tokyo_app.id

  referenced_security_group_id = (
    module.database[0].rds_security_group_id
  )

  ip_protocol = "tcp"
  from_port   = 3306
  to_port     = 3306

  description = "Approved MySQL traffic to Tokyo RDS"
}
