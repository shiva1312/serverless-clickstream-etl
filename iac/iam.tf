
# IAM Role for AWS Glue

resource "aws_iam_role" "glue_role" {
  name = "glue-etl-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Least-Privilege Glue Policy

resource "aws_iam_policy" "glue_least_privilege" {
  name = "GlueLeastPrivilegePolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # Glue job permissions
      {
        Effect = "Allow"
        Action = [
          "glue:GetJob",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:StartJobRun"
        ]
        Resource = "*"
      },

      # Read raw data + scripts
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.raw.arn,
          "${aws_s3_bucket.raw.arn}/*",
          aws_s3_bucket.glue_scripts.arn,
          "${aws_s3_bucket.glue_scripts.arn}/*"
        ]
      },

      # Write processed data
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.processed.arn,
          "${aws_s3_bucket.processed.arn}/*"
        ]
      },

      # CloudWatch logging
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },

      # Required for Glue
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.glue_role.arn
      }
    ]
  })
}


# Attach Policy to Role

resource "aws_iam_role_policy_attachment" "glue_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_least_privilege.arn
}

