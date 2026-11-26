
# -------------------------------------------
# Tokyo private application EC2
# -------------------------------------------

data "aws_ssm_parameter" "tokyo_al2023_ami" {
  count = var.enable_tokyo_compute ? 1 : 0

  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# HTTPS access to approved AWS interface endpoints.

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

  description = "HTTPS to approved interface endpoints"
}

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

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 12
    encrypted             = true
    delete_on_termination = true
  }

  # Small bootstrap script.
  # Application code and wheels live in S3.
  user_data = templatefile(
    "${path.module}/bootstrap.sh.tftpl",
    {
      aws_region = var.aws_region

      parameter_prefix = "/lab3/tokyo/db"

      db_instance_identifier = "${var.project_name}-mysql"

      artifact_bucket = aws_s3_bucket.tokyo_artifacts[0].bucket
      artifact_key    = "releases/tokyo-app-bundle.tar.gz"

      artifact_sha256 = var.tokyo_bundle_sha256

      log_group_name = aws_cloudwatch_log_group.tokyo_app[0].name
    }
  )

  lifecycle {
    precondition {
      condition = (
        var.enable_tokyo_database &&
        var.enable_tokyo_private_endpoints &&
        var.enable_tokyo_artifact_bucket &&
        var.enable_tokyo_monitoring &&
        var.tokyo_bootstrap_ready &&
        can(regex("^[0-9a-f]{64}$", var.tokyo_bundle_sha256))
      )

      error_message = "Tokyo EC2 requires RDS, private endpoints, an artifact bucket, monitoring, an approved bootstrap, and a 64-character SHA256 checksum."
    }
  }

  depends_on = [
    aws_iam_role_policy.tokyo_db_config_read,
    aws_iam_role_policy.tokyo_artifact_read,
    aws_iam_role_policy.tokyo_observability,
    aws_vpc_endpoint.tokyo_s3,
    aws_cloudwatch_log_group.tokyo_app
  ]

  tags = {
    Name = "${var.project_name}-app01"
    Role = "tokyo-application"
  }
}
