########################################
# IAM Role for AWS Glue (Job + Crawler)
########################################

resource "aws_iam_role" "glue_role" {
  name = "glue-etl-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "glue.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

########################################
# Least-Privilege Glue Policy (FINAL)
########################################

resource "aws_iam_policy" "glue_least_privilege" {
  name = "GlueLeastPrivilegePolicy-${var.environment}-${data.aws_caller_identity.current.account_id}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      ########################################
      # Glue job control (scoped to one job)
      ########################################
      {
        Effect = "Allow",
        Action = [
          "glue:GetJob",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:StartJobRun"
        ],
        Resource = aws_glue_job.etl.arn
      },

      ########################################
      # Glue crawler + catalog permissions
      # Resource "*" required due to Glue ARN limitations
      ########################################
      {
        Effect = "Allow",
        Action = [
          "glue:GetCrawler",
          "glue:GetCrawlerMetrics",
          "glue:StartCrawler",
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:CreateTable",
          "glue:UpdateTable"
        ],
        Resource = "*"
      },

      ########################################
      # Read raw bucket (bucket-level)
      ########################################
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        Resource = aws_s3_bucket.raw.arn
      },

      ########################################
      # Read raw objects (object-level)
      ########################################
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = "${aws_s3_bucket.raw.arn}/*"
      },

      ########################################
      # Glue scripts bucket (bucket-level)
      ########################################
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        Resource = aws_s3_bucket.glue_scripts.arn
      },

      ########################################
      # Glue script object access
      ########################################
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = [
          "${aws_s3_bucket.glue_scripts.arn}/transform_json_to_parquet.py",
          "${aws_s3_bucket.glue_scripts.arn}/*"
        ]
      },

      ########################################
      # Processed bucket (bucket-level)
      ########################################
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        Resource = aws_s3_bucket.processed.arn
      },

      ########################################
      # Write processed objects
      ########################################
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:AbortMultipartUpload"
        ],
        Resource = "${aws_s3_bucket.processed.arn}/*"
      },

      ########################################
      # CloudWatch logs (scoped to Glue)
      ########################################
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/*",
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/*:log-stream:*"
        ]
      },

      ########################################
      # PassRole (Glue requirement)
      ########################################
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = aws_iam_role.glue_role.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_least_privilege.arn
}
