
# Security group for private AWS interface endpoints
resource "aws_security_group" "endpoints" {
  name        = "${var.project_name}-vpce-sg"
  description = "HTTPS access to private AWS endpoints"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-vpce-sg"
  }
}

# Permit HTTPS from within the VPC
resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.endpoints.id
  cidr_ipv4         = var.vpc_cidr_block
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# Private AWS service connections
resource "aws_vpc_endpoint" "interface" {
  for_each = toset([
    "ssm",
    "ssmmessages",
    "ec2messages",
    "logs",
    "secretsmanager",
    "monitoring"
  ])

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = var.endpoint_subnet_ids
  security_group_ids = [aws_security_group.endpoints.id]

  tags = {
    Name = "${var.project_name}-${each.value}-endpoint"
  }
}

# Private access to Amazon S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = var.private_route_table_ids

  tags = {
    Name = "${var.project_name}-s3-endpoint"
  }
}

module "vpc_endpoints" {
  source = "./modules/vpc_endpoints"

  project_name = var.project_name
  aws_region   = var.aws_region

  vpc_id         = module.networking.vpc_id
  vpc_cidr_block = module.networking.vpc_cidr_block

  endpoint_subnet_ids = [
    module.networking.private_subnet_ids[0]
  ]

  private_route_table_ids = [
    module.networking.private_route_table_id
  ]
}
