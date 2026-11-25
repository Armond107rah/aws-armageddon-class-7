
# -------------------------------------------
# Tokyo private AWS service connectivity
# -------------------------------------------

# The application uses these AWS APIs without direct public internet access.

locals {
  tokyo_interface_services = toset([
    "ssm",
    "ssmmessages",
    "secretsmanager",
    "logs",
    "monitoring"
  ])
}

# Security group for endpoint network interfaces.
# No general VPC-wide access is granted.

resource "aws_security_group" "tokyo_endpoint_sg" {
  count = var.enable_tokyo_private_endpoints ? 1 : 0

  name_prefix = "${var.project_name}-endpoints-"
  description = "Private AWS service endpoints"
  vpc_id      = module.networking.vpc_id

  tags = {
    Name = "${var.project_name}-endpoint-sg"
  }
}

# Only the approved Tokyo application SG
# can reach these endpoints on HTTPS.

resource "aws_vpc_security_group_ingress_rule" "tokyo_endpoint_https" {
  count = var.enable_tokyo_private_endpoints ? 1 : 0

  security_group_id = (
    aws_security_group.tokyo_endpoint_sg[0].id
  )

  referenced_security_group_id = (
    aws_security_group.tokyo_app.id
  )

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "HTTPS from Tokyo application"
}

# Interface endpoints for private AWS APIs.

resource "aws_vpc_endpoint" "tokyo_interface" {
  for_each = (
    var.enable_tokyo_private_endpoints
    ? local.tokyo_interface_services
    : toset([])
  )

  vpc_id = module.networking.vpc_id

  service_name = (
    "com.amazonaws.${var.aws_region}.${each.value}"
  )

  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  # One AZ initially to reduce lab costs.
  # Multi-AZ endpoint resilience is a later
  # production-readiness consideration.
  subnet_ids = [
    module.networking.private_subnet_ids[0]
  ]

  security_group_ids = [
    aws_security_group.tokyo_endpoint_sg[0].id
  ]

  depends_on = [
    aws_vpc_security_group_ingress_rule.tokyo_endpoint_https
  ]

  tags = {
    Name = "${var.project_name}-${each.value}-vpce"
  }
}

# S3 Gateway Endpoint.
# Associates with the Tokyo private route table.

resource "aws_vpc_endpoint" "tokyo_s3" {
  count = var.enable_tokyo_private_endpoints ? 1 : 0

  vpc_id = module.networking.vpc_id

  service_name = (
    "com.amazonaws.${var.aws_region}.s3"
  )

  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    module.networking.private_route_table_id
  ]

  tags = {
    Name = "${var.project_name}-s3-gateway"
  }
}
