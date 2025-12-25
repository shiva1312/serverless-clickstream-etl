########################################
# AWS Glue Job
########################################

resource "aws_glue_job" "etl" {
  name     = "clickstream-etl-${var.environment}"
  role_arn = aws_iam_role.glue_role.arn

  glue_version = "4.0"
  max_retries  = 1

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/transform_json_to_parquet.py"
    python_version  = "3"
  }

  # Recommended job settings for reliability / idempotency / observability
  default_arguments = {
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "true"
    "--enable-spark-ui"                  = "true"

    # Glue temp directory
    "--TempDir" = "s3://${aws_s3_bucket.processed.bucket}/_glue_temp/"

    # Parameters consumed by the Glue script
    "--SOURCE_S3" = "s3://${aws_s3_bucket.raw.bucket}/"
    "--TARGET_S3" = "s3://${aws_s3_bucket.processed.bucket}/"
  }
}

########################################
# AWS Glue Crawler
########################################

resource "aws_glue_crawler" "crawler" {
  name          = "clickstream-crawler-${var.environment}"
  role          = aws_iam_role.glue_role.arn
  database_name = "clickstream_db"

  s3_target {
    path = "s3://${aws_s3_bucket.processed.bucket}/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }
}
