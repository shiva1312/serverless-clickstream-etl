resource "aws_athena_database" "db" {
  name   = "clickstream_db"
  bucket = aws_s3_bucket.processed.bucket
}


