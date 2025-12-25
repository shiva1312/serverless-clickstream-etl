########################################
# Helpers for globally-unique bucket names
########################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  bucket_suffix = "${var.environment}-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
}

########################################
# Raw Clickstream Data Bucket
########################################

resource "aws_s3_bucket" "raw" {
  bucket        = "clickstream-raw-${local.bucket_suffix}"
  force_destroy = true

  tags = {
    Name        = "clickstream-raw"
    Environment = var.environment
  }
}

########################################
# Processed (Parquet) Data Bucket
########################################

resource "aws_s3_bucket" "processed" {
  bucket        = "clickstream-processed-${local.bucket_suffix}"
  force_destroy = true

  tags = {
    Name        = "clickstream-processed"
    Environment = var.environment
  }
}

########################################
# Glue Scripts Bucket
########################################

resource "aws_s3_bucket" "glue_scripts" {
  bucket        = "clickstream-glue-scripts-${local.bucket_suffix}"
  force_destroy = true

  tags = {
    Name        = "glue-scripts"
    Environment = var.environment
  }
}

########################################
# Security Defaults 
########################################

# Block public access on all buckets
resource "aws_s3_bucket_public_access_block" "raw" {
  bucket                  = aws_s3_bucket.raw.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "processed" {
  bucket                  = aws_s3_bucket.processed.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "glue_scripts" {
  bucket                  = aws_s3_bucket.glue_scripts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Default encryption (SSE-S3) on all buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "glue_scripts" {
  bucket = aws_s3_bucket.glue_scripts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Optional: versioning (helps if scripts/data get overwritten)
resource "aws_s3_bucket_versioning" "glue_scripts" {
  bucket = aws_s3_bucket.glue_scripts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Optional: lifecycle to control cost on raw data (adjust as needed)
resource "aws_s3_bucket_lifecycle_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id

  rule {
    id     = "expire-raw-after-30-days"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}
