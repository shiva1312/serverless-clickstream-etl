
# Serverless Clickstream ETL Pipeline

This project implements a serverless data engineering pipeline on AWS that ingests JSON clickstream data, transforms it into Parquet format, and enables analytics using Amazon Athena.

## Architecture Overview
- Amazon Kinesis Data Firehose ingests clickstream events
- Raw JSON data is stored in Amazon S3
- AWS Glue ETL job transforms JSON → Parquet and removes sensitive fields
- AWS Glue Crawler catalogs the processed data
- Amazon Athena queries the transformed data

## Folder Structure
- `iac/` – Terraform Infrastructure as Code
- `glue/` – AWS Glue ETL transformation scripts

## Athena Sample Queries

```sql
SELECT COUNT(*) FROM clickstream_table;

SELECT event_type, COUNT(*) 
FROM clickstream_table
GROUP BY event_type
LIMIT 10;
AI Tooling Disclosure
ChatGPT was used to:

Debug AWS Glue job errors


Refactor ETL scripts

# Infrastructure as Code (Terraform)

This folder provisions all AWS resources using Terraform.

## Resources Created
- S3 buckets (raw & processed)
- IAM roles and policies
- Kinesis Data Firehose
- AWS Glue Job
- AWS Glue Crawler
- Athena Database

## How to Deploy

```bash
terraform init
terraform apply
Ensure AWS credentials are configured before running.



#  `iac/provider.tf`

```hcl
provider "aws" {
  region = "us-east-1"
}
