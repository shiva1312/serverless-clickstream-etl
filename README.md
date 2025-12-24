

# Serverless Clickstream ETL Pipeline

## Overview

This project implements a **serverless clickstream data pipeline on AWS** using Infrastructure as Code (Terraform) and AWS managed services.
Raw JSON clickstream events are ingested, transformed, and stored as **partitioned Parquet data** for efficient analytics using Amazon Athena.

The solution follows **AWS best practices** for:

* Least-privilege IAM
* Idempotent ETL processing
* Schema enforcement
* Partitioned S3 storage
* Logging and monitoring
* Environment-based configuration (no hard-coded values)

---

## Architecture

### Data Flow

1. **Amazon Kinesis Data Firehose**

   * Ingests clickstream JSON events

2. **Amazon S3 (Raw Zone)**

   * Stores raw clickstream data

3. **AWS Glue ETL Job**

   * Reads raw JSON data
   * Enforces schema
   * Removes sensitive fields
   * Converts data to Parquet
   * Writes partitioned output
   * Uses job bookmarks
   * Logs metrics and errors

4. **Amazon S3 (Processed Zone)**

   * Stores partitioned Parquet data

5. **AWS Glue Crawler**

   * Catalogs processed data

6. **Amazon Athena**

   * Queries transformed data

---

## S3 Data Layout (Partitioned)

Processed data is written using Hive-style partitions:

```text
s3://clickstream-processed-<env>/
  └── year=YYYY/
      └── month=MM/
          └── day=DD/
              └── part-*.parquet
```

Partitioning improves query performance and reduces Athena costs.

---

## Project Structure

```text
serverless-clickstream-etl/
│
├── iac/
│   ├── main.tf
│   ├── s3.tf
│   ├── firehose.tf
│   ├── glue.tf
│   ├── iam.tf
│   └── athena.tf
│
├── glue/
│   └── transform_json_to_parquet.py
│
├── README.md
```

---

## Infrastructure as Code (Terraform)

All AWS resources are provisioned using **Terraform**.

### Resources Created

* Amazon S3 buckets

  * Raw data bucket
  * Processed (Parquet) bucket
  * Glue scripts bucket
* IAM Role with **least-privilege policies**
* Kinesis Data Firehose
* AWS Glue ETL Job
* AWS Glue Crawler
* Athena Database

---

## Glue ETL Job Design

### Key Features Implemented

✔ **No hard-coded values**
All S3 buckets are passed as Glue job arguments.

✔ **Explicit schema control**
Schema is defined using Spark `StructType`.

✔ **Job lifecycle management**
`Job.init()` and `Job.commit()` implemented.

✔ **Job bookmarks enabled**
Ensures idempotent processing.

✔ **Partitioned output**
Data written using `year`, `month`, `day`.

✔ **Sensitive data handling**
Removes `ip_address` and `user_agent`.

✔ **Logging & error handling**
Integrated with CloudWatch Logs.

---

## Sample Athena Queries

```sql
-- Total events
SELECT COUNT(*) 
FROM clickstream_table;

-- Event frequency
SELECT event_type, COUNT(*) 
FROM clickstream_table
GROUP BY event_type
ORDER BY COUNT(*) DESC;

-- Daily event volume
SELECT year, month, day, COUNT(*) 
FROM clickstream_table
GROUP BY year, month, day
ORDER BY year, month, day;
```

---

## Deployment Steps

### Prerequisites

* AWS CLI configured
* Terraform installed
* Valid AWS credentials

### Deploy Infrastructure

```bash
cd iac
terraform init
terraform apply
```

### Upload Glue Script

```bash
aws s3 cp glue/transform_json_to_parquet.py \
  s3://<glue-scripts-bucket>/transform_json_to_parquet.py
```

### Run Glue Job

```bash
aws glue start-job-run --job-name clickstream-etl
```

---

## IAM Security Model

* Least-privilege IAM policy
* Scoped S3 read/write permissions
* CloudWatch logging access
* Explicit `iam:PassRole` for Glue

No wildcard permissions (`s3:*`, `glue:*`) are used.

---

## AI Tooling Disclosure

AI tools (ChatGPT) were used to:

* Refactor Glue ETL scripts
* Improve Terraform IAM policies
* Debug Glue job execution errors
* Align implementation with AWS best practices

All outputs were reviewed, tested, and validated.

---

## Outcome

This project demonstrates:

* Production-grade AWS ETL architecture
* Secure, scalable serverless design
* Strong Terraform and Glue expertise
* Optimized analytics using Athena

