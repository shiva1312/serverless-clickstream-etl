# AWS Glue ETL Script

## Overview
This AWS Glue job processes raw clickstream JSON data and produces partitioned Parquet files optimized for analytics.

## What It Does
- Reads JSON clickstream data from the raw S3 bucket
- Applies an explicit schema
- Removes sensitive fields (IP address, user agent)
- Converts data to Parquet format
- Partitions output by `year/month/day`
- Writes invalid records to a quarantine path
- Supports Glue job bookmarks for incremental processing

## Input
s3://clickstream-raw-<env>/year=YYYY/month=MM/day=DD/

## Output
s3://clickstream-processed-<env>/year=YYYY/month=MM/day=DD/

### Quarantine
s3://clickstream-processed-<env>/_quarantine/

## Job Arguments
- `--SOURCE_S3` : Raw S3 input path  
- `--TARGET_S3` : Processed S3 output path  

## Notes
- Glue job bookmarks must be enabled
- Logs are written to Amazon CloudWatch
- Output data is cataloged using AWS Glue Crawler and queried via Amazon Athena
