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
# Least-Privilege Glue Policy
########################################
# Fix: add ListBucket on glue_scripts bucket AND allow GetObject on the exact script key
# This resolves: "not authorized to perform s3:ListBucket" when Glue downloads the script
########################################

resource "aws_iam_policy" "glue_least_privilege" {
  name = "GlueLeastPrivilegePolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      ########################################
      # Glue job permissions (scoped)
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
      # Glue resources are not always easily ARN-scopable,
      # so these remain at "*" but actions are tightly limited.
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
      # Required for Glue to locate/download script from S3.
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
      # Glue script object access (object-level)
      # Allow exact script path + any future scripts under the bucket.
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
      # Write processed objects (object-level)
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
      # CloudWatch logs (scoped)
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
      # PassRole required by Glue
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
