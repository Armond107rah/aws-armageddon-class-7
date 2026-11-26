
# -------------------------------------------
# Tokyo private application artifact storage
# -------------------------------------------

resource "aws_s3_bucket" "tokyo_artifacts" {
  count = var.enable_tokyo_artifact_bucket ? 1 : 0

  bucket_prefix = "${var.project_name}-artifacts-"
  force_destroy = false

  tags = {
    Name    = "${var.project_name}-artifacts"
    Purpose = "private-application-deployment"
  }
}

# Block public S3 access.

resource "aws_s3_bucket_public_access_block" "tokyo_artifacts" {
  count = var.enable_tokyo_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.tokyo_artifacts[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encrypt stored S3 objects.

resource "aws_s3_bucket_server_side_encryption_configuration" "tokyo_artifacts" {
  count = var.enable_tokyo_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.tokyo_artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Deny requests that do not use HTTPS.

resource "aws_s3_bucket_policy" "tokyo_artifacts_tls" {
  count = var.enable_tokyo_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.tokyo_artifacts[0].id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"

      Resource = [
        aws_s3_bucket.tokyo_artifacts[0].arn,
        "${aws_s3_bucket.tokyo_artifacts[0].arn}/*"
      ]

      Condition = {
        Bool = {
          "aws:SecureTransport" = "false"
        }
      }
    }]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.tokyo_artifacts
  ]
}

# Allow the application role to read only
# the approved deployment archive.

resource "aws_iam_role_policy" "tokyo_artifact_read" {
  count = var.enable_tokyo_artifact_bucket ? 1 : 0

  name = "${var.project_name}-artifact-read"
  role = module.iam.role_name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "s3:GetObject"
      ]

      Resource = (
        "${aws_s3_bucket.tokyo_artifacts[0].arn}/releases/tokyo-app-bundle.tar.gz"
      )
    }]
  })
}

# Permit S3 HTTPS traffic through the
# existing regional S3 gateway endpoint.

resource "aws_vpc_security_group_egress_rule" "tokyo_s3_https" {
  count = (
    var.enable_tokyo_compute &&
    var.enable_tokyo_private_endpoints
  ) ? 1 : 0

  security_group_id = aws_security_group.tokyo_app.id

  prefix_list_id = (
    aws_vpc_endpoint.tokyo_s3[0].prefix_list_id
  )

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "HTTPS to regional Amazon S3"
}
