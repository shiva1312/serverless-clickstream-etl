########################################
# Amazon Athena Database
########################################

resource "aws_athena_database" "db" {
  name = "clickstream_db"

  bucket = aws_s3_bucket.processed.bucket

  # Dedicated prefix for Athena metadata
  properties = {
    location = "s3://${aws_s3_bucket.processed.bucket}/athena/"
  }

  force_destroy = true
}
