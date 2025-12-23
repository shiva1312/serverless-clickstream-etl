# AWS Glue ETL Script

This Glue job:
- Reads JSON clickstream data from the raw S3 bucket
- Removes sensitive fields
- Writes optimized Parquet files to the processed S3 bucket

## Input
s3://clickstream-raw-*

## Output
s3://clickstream-processed-*
