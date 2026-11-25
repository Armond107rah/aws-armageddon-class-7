
# -------------------------------------------
# Tokyo EC2 application foundation
# -------------------------------------------

# Deployment remains disabled by default.
# Use the official public SSM parameter to identify an Amazon Linux 2023 AMI in Tokyo.

data "aws_ssm_parameter" "tokyo_al2023_ami" {
  count = var.enable_tokyo_compute ? 1 : 0

  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Permit HTTPS traffic to private AWS service endpoints located inside the Tokyo VPC.
#
# This does NOT provide internet access.


# EC2 may reach only the approved VPC endpoint security group on HTTPS.
# This rule exists when both compute and private endpoints are enabled.

resource "aws_vpc_security_group_egress_rule" "tokyo_https" {
  count = (
    var.enable_tokyo_compute &&
    var.enable_tokyo_private_endpoints
  ) ? 1 : 0

  security_group_id = aws_security_group.tokyo_app.id

  referenced_security_group_id = (
    aws_security_group.tokyo_endpoint_sg[0].id
  )

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "HTTPS to approved VPC endpoints"
}


# Private Tokyo application instance.

resource "aws_instance" "tokyo_app" {
  count = var.enable_tokyo_compute ? 1 : 0

  ami = data.aws_ssm_parameter.tokyo_al2023_ami[0].value

  instance_type = var.tokyo_instance_type

  subnet_id = module.networking.private_subnet_ids[0]

  vpc_security_group_ids = [
    aws_security_group.tokyo_app.id
  ]

  iam_instance_profile = module.iam.instance_profile_name

  associate_public_ip_address = false

  # Require IMDSv2 for instance metadata access.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Encrypt the instance root volume.
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 12
    encrypted             = true
    delete_on_termination = true
  }

  # Reuse the Lab 2 app while correcting the Tokyo-specific runtime settings.
  user_data = templatefile(
    "${path.module}/bootstrap.sh.tftpl",
    {
      aws_region = var.aws_region

      parameter_prefix = "/lab3/tokyo/db"

      db_instance_identifier = "${var.project_name}-mysql"

      app_b64 = base64encode(
        file("${path.module}/../../../lab-2/infrastructure/app/app.py")
      )

      requirements_b64 = base64encode(
        file("${path.module}/../../../lab-2/infrastructure/app/requirements.txt")
      )
    }
  )

  lifecycle {
    precondition {
      condition = (
        var.enable_tokyo_database &&
        var.enable_tokyo_private_endpoints &&
        var.tokyo_bootstrap_ready
      )

      error_message = "Tokyo EC2 requires RDS, private endpoints, and an approved bootstrap configuration."
    }
  }

  depends_on = [
    aws_iam_role_policy.tokyo_db_config_read
  ]

  tags = {
    Name = "${var.project_name}-app01"
    Role = "tokyo-application"
  }
}
