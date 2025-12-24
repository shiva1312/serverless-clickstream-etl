
# Raw Clickstream Data Bucket

resource "aws_s3_bucket" "raw" {
  bucket        = "clickstream-raw-${var.environment}"
  force_destroy = true

  tags = {
    Name        = "clickstream-raw"
    Environment = var.environment
  }
}


# Processed (Parquet) Data Bucket

resource "aws_s3_bucket" "processed" {
  bucket        = "clickstream-processed-${var.environment}"
  force_destroy = true

  tags = {
    Name        = "clickstream-processed"
    Environment = var.environment
  }
}


# Glue Scripts Bucket

resource "aws_s3_bucket" "glue_scripts" {
  bucket        = "clickstream-glue-scripts-${var.environment}"
  force_destroy = true

  tags = {
    Name        = "glue-scripts"
    Environment = var.environment
  }
}

