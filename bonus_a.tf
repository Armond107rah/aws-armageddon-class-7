############################################
# Bonus A - Data + Locals
############################################

# Explanation: lab1c wants to know “who am I in this galaxy?” so ARNs can be scoped properly.
data "aws_caller_identity" "lab1c_self01" {}

# Explanation: Region matters—hyperspace lanes change per sector.
data "aws_region" "lab1c_region01" {}

locals {
  # Explanation: Name prefix is the roar that echoes through every tag.
  lab1c_prefix = var.project_name

  # TODO: Students should lock this down after apply using the real secret ARN from outputs/state
  lab1c_secret_arn_guess = "arn:aws:secretsmanager:${data.aws_region.lab1c_region01.id}:${data.aws_caller_identity.lab1c_self01.account_id}:secret:${local.lab1c_prefix}/rds/mysql*"
}

############################################
# Move EC2 into PRIVATE subnet (no public IP)
############################################

# Explanation: lab1c hates exposure—private subnets keep your compute off the public holonet.
resource "aws_instance" "lab1c_ec2" {
  ami                   = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.lab1c_private_subnets[0].id
  vpc_security_group_ids = [aws_security_group.lab1c_ec2_sg01.id]
  iam_instance_profile   = aws_iam_instance_profile.lab1c_instance_profile01.name

  # TODO: Students should remove/disable SSH inbound rules entirely and rely on SSM.
  # TODO: Students add user_data that installs app + CW agent; for true hard mode use a baked AMI.
  # TODO: student supplies user_data to install app + CW agent + configure log shipping
  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "${local.lab1c_prefix}-ec201-private"
  }
}

############################################
# Security Group for VPC Interface Endpoints
############################################

# Explanation: Even endpoints need guards—lab1c posts a Wookiee at every airlock.
resource "aws_security_group" "lab1c_vpce_sg01" {
  name        = "${local.lab1c_prefix}-vpce-sg01"
  description = "SG for VPC Interface Endpoints"
  vpc_id      = aws_vpc.lab1c_vpc01.id

  # TODO: Students must allow inbound 443 FROM the EC2 SG (or VPC CIDR) to endpoints.
  # NOTE: Interface endpoints ENIs receive traffic on 443.

  tags = {
    Name = "${local.lab1c_prefix}-vpce-sg01"
  }
}
resource "aws_vpc_security_group_ingress_rule" "from-ec2" {
  description = "Http from Ec2 to endpoints"
  security_group_id = aws_security_group.lab1c_vpce_sg01.id
  referenced_security_group_id = "sg-06c185c6c81d8ac58"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443

  tags = {
    Name = "Endpoints"
  }
}
############################################
# VPC Endpoint - S3 (Gateway)
############################################

# Explanation: S3 is the supply depot—without this, your private world starves (updates, artifacts, logs).
resource "aws_vpc_endpoint" "lab1c_vpce_s3_gw01" {
  vpc_id            = aws_vpc.lab1c_vpc01.id
  service_name      = "com.amazonaws.${data.aws_region.lab1c_region01.id}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.lab1c_private_rt01.id
  ]

  tags = {
    Name = "${local.lab1c_prefix}-vpce-s3-gw01"
  }
}

############################################
# VPC Endpoints - SSM (Interface)
############################################

# Explanation: SSM is your Force choke—remote control without SSH, and nobody sees your keys.
resource "aws_vpc_endpoint" "lab1c_vpce_ssm01" {
  vpc_id              = aws_vpc.lab1c_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.lab1c_region01.id}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.lab1c_private_subnets[*].id
  security_group_ids = [aws_security_group.lab1c_vpce_sg01.id]

  tags = {
    Name = "${local.lab1c_prefix}-vpce-ssm01"
  }
}

# Explanation: ec2messages is the Wookiee messenger—SSM sessions won’t work without it.
resource "aws_vpc_endpoint" "lab1c_vpce_ec2messages01" {
  vpc_id              = aws_vpc.lab1c_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.lab1c_region01.id}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.lab1c_private_subnets[*].id
  security_group_ids = [aws_security_group.lab1c_vpce_sg01.id]

  tags = {
    Name = "${local.lab1c_prefix}-vpce-ec2messages01"
  }
}

# Explanation: ssmmessages is the holonet channel—Session Manager needs it to talk back.
resource "aws_vpc_endpoint" "lab1c_vpce_ssmmessages01" {
  vpc_id              = aws_vpc.lab1c_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.lab1c_region01.id}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.lab1c_private_subnets[*].id
  security_group_ids = [aws_security_group.lab1c_vpce_sg01.id]

  tags = {
    Name = "${local.lab1c_prefix}-vpce-ssmmessages01"
  }
}

############################################
# VPC Endpoint - CloudWatch Logs (Interface)
############################################

# Explanation: CloudWatch Logs is the ship’s black box—lab1c wants crash data, always.
resource "aws_vpc_endpoint" "lab1c_vpce_logs01" {
  vpc_id              = aws_vpc.lab1c_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.lab1c_region01.id}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.lab1c_private_subnets[*].id
  security_group_ids = [aws_security_group.lab1c_vpce_sg01.id]

  tags = {
    Name = "${local.lab1c_prefix}-vpce-logs01"
  }
}

############################################
# VPC Endpoint - Secrets Manager (Interface)
############################################

# Explanation: Secrets Manager is the locked vault—lab1c doesn’t put passwords on sticky notes.
resource "aws_vpc_endpoint" "lab1c_vpce_secrets01" {
  vpc_id              = aws_vpc.lab1c_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.lab1c_region01.id}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.lab1c_private_subnets[*].id
  security_group_ids = [aws_security_group.lab1c_vpce_sg01.id]

  tags = {
    Name = "${local.lab1c_prefix}-vpce-secrets01"
  }
}

############################################
# Optional: VPC Endpoint - KMS (Interface)
############################################

# Explanation: KMS is the encryption kyber crystal—lab1c prefers locked doors AND locked safes.
resource "aws_vpc_endpoint" "lab1c_vpce_kms01" {
  vpc_id              = aws_vpc.lab1c_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.lab1c_region01.id}.kms"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.lab1c_private_subnets[*].id
  security_group_ids = [aws_security_group.lab1c_vpce_sg01.id]

  tags = {
    Name = "${local.lab1c_prefix}-vpce-kms01"
  }
}

############################################
# Least-Privilege IAM (BONUS A)
############################################

# Explanation: lab1c doesn’t hand out the Falcon keys—this policy scopes reads to your lab paths only.
resource "aws_iam_policy" "lab1c_leastpriv_read_params01" {
  name        = "${local.lab1c_prefix}-lp-ssm-read01"
  description = "Least-privilege read for SSM Parameter Store under /lab/db/*"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadLabDbParams"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.lab1c_region01.id}:${data.aws_caller_identity.lab1c_self01.account_id}:parameter/lab/db/*"
        ]
      }
    ]
  })
}

# Explanation: lab1c only opens *this* vault—GetSecretValue for only your secret (not the whole planet).
resource "aws_iam_policy" "lab1c_leastpriv_read_secret01" {
  name        = "${local.lab1c_prefix}-lp-secrets-read01"
  description = "Least-privilege read for the lab DB secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadOnlyLabSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = local.lab1c_secret_arn_guess
      }
    ]
  })
}

# Explanation: When the Falcon logs scream, this lets lab1c ship logs to CloudWatch without giving away the Death Star plans.
resource "aws_iam_policy" "lab1c_leastpriv_cwlogs01" {
  name        = "${local.lab1c_prefix}-lp-cwlogs01"
  description = "Least-privilege CloudWatch Logs write for the app log group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.lab1c_log_group01.arn}:*"
        ]
      }
    ]
  })
}

# Explanation: Attach the scoped policies—lab1c loves power, but only the safe kind.
resource "aws_iam_role_policy_attachment" "lab1c_attach_lp_params01" {
  role       = aws_iam_role.lab1c_ec2_role01.name
  policy_arn = aws_iam_policy.lab1c_leastpriv_read_params01.arn
}

resource "aws_iam_role_policy_attachment" "lab1c_attach_lp_secret01" {
  role       = aws_iam_role.lab1c_ec2_role01.name
  policy_arn = aws_iam_policy.lab1c_leastpriv_read_secret01.arn
}

resource "aws_iam_role_policy_attachment" "lab1c_attach_lp_cwlogs01" {
  role       = aws_iam_role.lab1c_ec2_role01.name
  policy_arn = aws_iam_policy.lab1c_leastpriv_cwlogs01.arn
}