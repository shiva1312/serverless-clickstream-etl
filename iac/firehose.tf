########################################
# IAM Role for Kinesis Data Firehose
########################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "firehose_role" {
  name = "firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "firehose.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

########################################
# Least-Privilege Policy for Firehose -> S3
########################################

resource "aws_iam_policy" "firehose_s3_least_privilege" {
  name = "FirehoseS3LeastPrivilegePolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # Allow Firehose to write objects into the raw bucket (object-level)
      {
        Effect = "Allow",
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ],
        Resource = [
          aws_s3_bucket.raw.arn,
          "${aws_s3_bucket.raw.arn}/*"
        ]
      },

      # CloudWatch Logs for delivery errors (scoped)
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesisfirehose/*",
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesisfirehose/*:log-stream:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_attach" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_s3_least_privilege.arn
}

########################################
# Kinesis Data Firehose Delivery Stream
########################################

resource "aws_kinesis_firehose_delivery_stream" "clickstream" {
  name        = "clickstream-firehose"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.raw.arn

    # REQUIRED: Partition raw data by date
    # Firehose replaces these with timestamps at delivery time.
    prefix              = "clickstream/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "clickstream-errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    buffering_size     = 64   # MB
    buffering_interval = 60   # seconds

    compression_format = "UNCOMPRESSED"
  }
}
