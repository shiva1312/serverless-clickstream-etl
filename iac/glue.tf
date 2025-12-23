resource "aws_glue_job" "etl" {
  name     = "clickstream-etl"
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/transform_json_to_parquet.py"
    python_version  = "3"
  }

  glue_version = "4.0"
}

resource "aws_glue_crawler" "crawler" {
  name          = "clickstream-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = "clickstream_db"

  s3_target {
    path = "s3://${aws_s3_bucket.processed.bucket}"
  }
}

