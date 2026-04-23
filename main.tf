############################################
# Locals + Data Sources
############################################

locals {
  # Main naming prefix used across the lab.
  name_prefix = "lab-1c"

  # AZ layout for public/private subnet pairs.
  azs = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c",
  ]

  # Public subnets = internet-facing application layer
  public_subnets = {
    "us-east-1a" = "10.234.0.0/24"
    "us-east-1b" = "10.234.16.0/24"
    "us-east-1c" = "10.234.32.0/24"
  }

  # Private subnets = backend/data layer
  private_subnets = {
    "us-east-1a" = "10.234.128.0/24"
    "us-east-1b" = "10.234.144.0/24"
    "us-east-1c" = "10.234.160.0/24"
  }

  # If a KMS key is provided, store parameters as SecureString.
  ssm_parameter_type = var.securestring_kms_key_id == null ? "String" : "SecureString"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

############################################
# VPC + Internet Gateway
############################################

# Explanation:
# The VPC is the main network boundary for the lab.
# Public subnets host the EC2 app tier.
# Private subnets host the RDS database tier.
resource "aws_vpc" "lab1c_vpc01" {
  cidr_block           = "10.234.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc01"
  }
}

# Explanation:
# The Internet Gateway allows resources in public subnets to reach the internet.
resource "aws_internet_gateway" "lab1c_igw01" {
  vpc_id = aws_vpc.lab1c_vpc01.id

  tags = {
    Name = "${local.name_prefix}-igw01"
  }
}

############################################
# Subnets (Public + Private)
############################################

# Explanation:
# Public subnets are for internet-facing compute.
resource "aws_subnet" "lab1c_public_subnets" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.lab1c_vpc01.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet-${each.key}"
    Tier = "public"
  }
}

# Explanation:
# Private subnets are for backend resources like RDS.
resource "aws_subnet" "lab1c_private_subnets" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.lab1c_vpc01.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "${local.name_prefix}-private-subnet-${each.key}"
    Tier = "private"
  }
}

############################################
# NAT Gateway + Elastic IP
############################################

# Explanation:
# The NAT Gateway allows private subnets to reach the internet for updates
# without allowing inbound internet access into those subnets.
resource "aws_eip" "lab1c_nat_eip01" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip01"
  }
}

resource "aws_nat_gateway" "lab1c_nat01" {
  allocation_id = aws_eip.lab1c_nat_eip01.id
  subnet_id     = aws_subnet.lab1c_public_subnets["us-east-1a"].id

  depends_on = [aws_internet_gateway.lab1c_igw01]

  tags = {
    Name = "${local.name_prefix}-nat01"
  }
}

############################################
# Route Tables (Public + Private)
############################################

# Public route table
resource "aws_route_table" "lab1c_public_rt01" {
  vpc_id = aws_vpc.lab1c_vpc01.id

  tags = {
    Name = "${local.name_prefix}-public-rt01"
  }
}

resource "aws_route" "lab1c_public_default_route" {
  route_table_id         = aws_route_table.lab1c_public_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab1c_igw01.id
}

resource "aws_route_table_association" "lab1c_public_rta" {
  for_each = aws_subnet.lab1c_public_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.lab1c_public_rt01.id
}

# Private route tables
resource "aws_route_table" "lab1c_private_rt01" {
  for_each = aws_subnet.lab1c_private_subnets

  vpc_id = aws_vpc.lab1c_vpc01.id

  tags = {
    Name = "${local.name_prefix}-private-rt-${each.key}"
  }
}

resource "aws_route" "lab1c_private_default_route" {
  for_each = aws_route_table.lab1c_private_rt01

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.lab1c_nat01.id
}

resource "aws_route_table_association" "lab1c_private_rta" {
  for_each = aws_subnet.lab1c_private_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.lab1c_private_rt01[each.key].id
}

############################################
# Security Groups (EC2 + RDS)
############################################

# Explanation:
# EC2 security group allows:
# - SSH from your IP only
# - HTTP from anywhere
resource "aws_security_group" "lab1c_ec2_sg01" {
  name        = "ec2-lab-sg"
  description = "EC2 application security group"
  vpc_id      = aws_vpc.lab1c_vpc01.id

  tags = {
    Name = "ec2-lab-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "lab1c_ec2_ssh" {
  security_group_id = aws_security_group.lab1c_ec2_sg01.id
  description       = "SSH from trusted IP"
  cidr_ipv4         = var.ssh_ingress_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "lab1c_ec2_http" {
  security_group_id = aws_security_group.lab1c_ec2_sg01.id
  description       = "HTTP from anywhere"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lab1c_ec2_egress_all" {
  security_group_id = aws_security_group.lab1c_ec2_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Explanation:
# RDS security group only allows MySQL traffic from the EC2 security group.
# This is safer than opening the DB to a CIDR range.
resource "aws_security_group" "lab1c_rds_sg01" {
  name        = "rds-lab-sg"
  description = "RDS MySQL security group"
  vpc_id      = aws_vpc.lab1c_vpc01.id

  tags = {
    Name = "rds-lab-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "lab1c_rds_mysql_from_ec2" {
  security_group_id            = aws_security_group.lab1c_rds_sg01.id
  referenced_security_group_id = aws_security_group.lab1c_ec2_sg01.id
  description                  = "MySQL from EC2 SG only"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lab1c_rds_egress_all" {
  security_group_id = aws_security_group.lab1c_rds_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

############################################
# EC2 AMI Lookup
############################################

data "aws_ami" "lab1c_amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############################################
# CloudWatch Log Group
############################################

# Explanation:
# This is the centralized destination for application logs.
# Your user_data/app must be configured to write or ship logs here.
resource "aws_cloudwatch_log_group" "lab1c_app_logs01" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${local.name_prefix}-app-logs"
  }
}

############################################
# RDS Subnet Group + MySQL Instance
############################################

resource "aws_db_subnet_group" "lab1c_rds_subnet_group01" {
  name       = "${local.name_prefix}-rds-subnet-group01"
  subnet_ids = values(aws_subnet.lab1c_private_subnets)[*].id

  tags = {
    Name = "${local.name_prefix}-rds-subnet-group01"
  }
}

resource "aws_db_instance" "lab1c_rds01" {
  identifier = "${local.name_prefix}-mysql"

  engine                 = "mysql"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  storage_type           = "gp3"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  multi_az               = false
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.lab1c_rds_subnet_group01.name
  vpc_security_group_ids = [aws_security_group.lab1c_rds_sg01.id]

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = {
    Name = "${local.name_prefix}-mysql"
  }
}

############################################
# Secrets Manager
############################################

# Explanation:
# Secrets Manager stores sensitive credentials and richer DB connection metadata.
resource "aws_secretsmanager_secret" "lab1c_db_secret01" {
  name = var.secret_name

  tags = {
    Name = var.secret_name
  }
}

resource "aws_secretsmanager_secret_version" "lab1c_db_secret_version01" {
  secret_id = aws_secretsmanager_secret.lab1c_db_secret01.id

  secret_string = jsonencode({
    username             = var.db_username
    password             = var.db_password
    engine               = "mysql"
    host                 = aws_db_instance.lab1c_rds01.address
    port                 = aws_db_instance.lab1c_rds01.port
    dbInstanceIdentifier = aws_db_instance.lab1c_rds01.identifier
  })
}

############################################
# SSM Parameter Store
############################################

# Explanation:
# Parameter Store keeps non-secret config values separate from credentials.
resource "aws_ssm_parameter" "lab1c_db_endpoint_param" {
  name   = "${var.ssm_param_prefix}/endpoint"
  type   = local.ssm_parameter_type
  value  = aws_db_instance.lab1c_rds01.address
  key_id = var.securestring_kms_key_id

  tags = {
    Name = "${local.name_prefix}-param-db-endpoint"
  }
}

resource "aws_ssm_parameter" "lab1c_db_port_param" {
  name   = "${var.ssm_param_prefix}/port"
  type   = local.ssm_parameter_type
  value  = tostring(aws_db_instance.lab1c_rds01.port)
  key_id = var.securestring_kms_key_id

  tags = {
    Name = "${local.name_prefix}-param-db-port"
  }
}

resource "aws_ssm_parameter" "lab1c_db_name_param" {
  name   = "${var.ssm_param_prefix}/name"
  type   = local.ssm_parameter_type
  value  = var.db_name
  key_id = var.securestring_kms_key_id

  tags = {
    Name = "${local.name_prefix}-param-db-name"
  }
}

############################################
# IAM Role + Instance Profile for EC2
############################################

data "aws_iam_policy_document" "lab1c_ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lab1c_ec2_inline" {
  statement {
    sid     = "ReadDbSecret"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret.lab1c_db_secret01.arn
    ]
  }

  statement {
    sid    = "ReadDbParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [
      aws_ssm_parameter.lab1c_db_endpoint_param.arn,
      aws_ssm_parameter.lab1c_db_port_param.arn,
      aws_ssm_parameter.lab1c_db_name_param.arn
    ]
  }

  dynamic "statement" {
    for_each = var.securestring_kms_key_id == null ? [] : [var.securestring_kms_key_id]
    content {
      sid       = "DecryptSecureString"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [statement.value]
    }
  }

  statement {
    sid    = "WriteAppLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.lab1c_app_logs01.arn,
      "${aws_cloudwatch_log_group.lab1c_app_logs01.arn}:*"
    ]
  }

  # CloudWatch PutMetricData is typically scoped with namespace conventions rather than resource ARN scoping.
  statement {
    sid       = "PutAppMetrics"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "lab1c_ec2_role01" {
  name               = "${local.name_prefix}-ec2-role01"
  assume_role_policy = data.aws_iam_policy_document.lab1c_ec2_assume_role.json

  tags = {
    Name = "${local.name_prefix}-ec2-role01"
  }
}

resource "aws_iam_role_policy_attachment" "lab1c_ec2_ssm_core" {
  role       = aws_iam_role.lab1c_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "lab1c_ec2_cw_agent" {
  role       = aws_iam_role.lab1c_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "lab1c_ec2_inline01" {
  name   = "${local.name_prefix}-ec2-inline01"
  role   = aws_iam_role.lab1c_ec2_role01.id
  policy = data.aws_iam_policy_document.lab1c_ec2_inline.json
}

resource "aws_iam_instance_profile" "lab1c_ec2_instance_profile01" {
  name = "${local.name_prefix}-instance-profile01"
  role = aws_iam_role.lab1c_ec2_role01.name

  tags = {
    Name = "${local.name_prefix}-instance-profile01"
  }
}

############################################
# EC2 Instance (Application Host)
############################################

# Explanation:
# Terraform sends the referenced shell script to EC2 as user data.
# cloud-init executes it on first boot.
resource "aws_instance" "lab1c_ec2_app01" {
  ami                         = data.aws_ami.lab1c_amzn2.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.lab1c_public_subnets["us-east-1a"].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.lab1c_ec2_sg01.id]
  iam_instance_profile        = aws_iam_instance_profile.lab1c_ec2_instance_profile01.name

  user_data                   = file("${path.module}/scripts/1a_user_data.sh")
  user_data_replace_on_change = true

  tags = {
    Name = "${local.name_prefix}-ec2"
  }
}

############################################
# SNS Topic + Email Subscription
############################################

resource "aws_sns_topic" "lab1c_alerts_topic01" {
  name = "${local.name_prefix}-alerts"

  tags = {
    Name = "${local.name_prefix}-alerts"
  }
}

resource "aws_sns_topic_subscription" "lab1c_alerts_email01" {
  count = var.alarm_email == null ? 0 : 1

  topic_arn = aws_sns_topic.lab1c_alerts_topic01.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

############################################
# CloudWatch Log Metric Filter + DB Failure Alarm
############################################

# Explanation:
# This filter turns matching ERROR log lines into a CloudWatch custom metric.
resource "aws_cloudwatch_log_metric_filter" "lab1c_db_connection_failure_filter01" {
  name           = "${local.name_prefix}-db-connection-failure-filter"
  log_group_name = aws_cloudwatch_log_group.lab1c_app_logs01.name
  pattern        = var.db_failure_filter_pattern

  metric_transformation {
    name      = var.db_failure_metric_name
    namespace = var.db_failure_metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "lab1c_db_connection_failure_alarm01" {
  alarm_name        = "${local.name_prefix}-db-connection-failure"
  alarm_description = "App logs indicate database connection failures."

  namespace           = var.db_failure_metric_namespace
  metric_name         = var.db_failure_metric_name
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.lab1c_alerts_topic01.arn]
  ok_actions    = [aws_sns_topic.lab1c_alerts_topic01.arn]
}

############################################
# Infrastructure Health Alarms
############################################

resource "aws_cloudwatch_metric_alarm" "lab1c_ec2_status_check_failed_alarm01" {
  alarm_name          = "${local.name_prefix}-ec2-status-check-failed"
  alarm_description   = "EC2 instance status check failed."
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.lab1c_ec2_app01.id
  }

  alarm_actions = [aws_sns_topic.lab1c_alerts_topic01.arn]
  ok_actions    = [aws_sns_topic.lab1c_alerts_topic01.arn]
}

resource "aws_cloudwatch_metric_alarm" "lab1c_ec2_cpu_high_alarm01" {
  alarm_name          = "${local.name_prefix}-ec2-cpu-high"
  alarm_description   = "EC2 CPU utilization is high."
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.lab1c_ec2_app01.id
  }

  alarm_actions = [aws_sns_topic.lab1c_alerts_topic01.arn]
  ok_actions    = [aws_sns_topic.lab1c_alerts_topic01.arn]
}

resource "aws_cloudwatch_metric_alarm" "lab1c_rds_cpu_high_alarm01" {
  alarm_name          = "${local.name_prefix}-rds-cpu-high"
  alarm_description   = "RDS CPU utilization is high."
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.lab1c_rds01.id
  }

  alarm_actions = [aws_sns_topic.lab1c_alerts_topic01.arn]
  ok_actions    = [aws_sns_topic.lab1c_alerts_topic01.arn]
}

resource "aws_cloudwatch_metric_alarm" "lab1c_rds_free_storage_low_alarm01" {
  alarm_name          = "${local.name_prefix}-rds-free-storage-low"
  alarm_description   = "RDS free storage space is low."
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 2147483648
  comparison_operator = "LessThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.lab1c_rds01.id
  }

  alarm_actions = [aws_sns_topic.lab1c_alerts_topic01.arn]
  ok_actions    = [aws_sns_topic.lab1c_alerts_topic01.arn]
}

resource "aws_cloudwatch_metric_alarm" "lab1c_nat_error_port_allocation_alarm01" {
  alarm_name          = "${local.name_prefix}-nat-error-port-allocation"
  alarm_description   = "NAT Gateway error port allocation > 0."
  namespace           = "AWS/NATGateway"
  metric_name         = "ErrorPortAllocation"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    NatGatewayId = aws_nat_gateway.lab1c_nat01.id
  }

  alarm_actions = [aws_sns_topic.lab1c_alerts_topic01.arn]
  ok_actions    = [aws_sns_topic.lab1c_alerts_topic01.arn]
}