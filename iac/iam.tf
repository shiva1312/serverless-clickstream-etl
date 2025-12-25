########################################
# IAM Role for AWS Glue (Job + Crawler)
########################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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

resource "aws_iam_policy" "glue_least_privilege" {
  name = "GlueLeastPrivilegePolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # Glue job permissions (scoped to the specific job)
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

      # Glue crawler + catalog permissions (minimal set)
      # Catalog resources can be tricky to scope tightly in small take-homes;
      # this is still far tighter than glue:*.
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

      # Read raw bucket (bucket-level)
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        Resource = [
          aws_s3_bucket.raw.arn,
          aws_s3_bucket.glue_scripts.arn
        ]
      },

      # Read raw + scripts (object-level)
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = [
          "${aws_s3_bucket.raw.arn}/*",
          "${aws_s3_bucket.glue_scripts.arn}/*"
        ]
      },

      # Write processed bucket (bucket-level)
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        Resource = [
          aws_s3_bucket.processed.arn
        ]
      },

      # Write processed data (object-level)
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:AbortMultipartUpload"
        ],
        Resource = [
          "${aws_s3_bucket.processed.arn}/*"
        ]
      },

      # CloudWatch logging (scoped to Glue log groups in this account/region)
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

      # Allow passing the Glue role (needed by Glue service/job execution)
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = aws_iam_role.glue_role.arn
      }
    ]
  })
}

########################################
# Attach policy to Glue role
########################################

resource "aws_iam_role_policy_attachment" "glue_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_least_privilege.arn
}
