provider "aws" {
  profile = "Kalirah1"
  region  = "us-east-1"
}

# Generate a random suffix to ensure global uniqueness
resource "random_id" "suffix" {
  byte_length = 4
}

# S3 Bucket
resource "aws_s3_bucket" "this" {
  bucket = "touseeq-bucket-${random_id.suffix.hex}"

  tags = {
    Name        = "touseeq-bucket"
    Environment = "dev"
  }
}

# Enable Versioning
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block Public Access (Best Practice)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable Server-Side Encryption (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}