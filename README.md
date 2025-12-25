

# Serverless Clickstream ETL Pipeline

## Overview
This project implements a **serverless clickstream data pipeline on AWS** using **Terraform** and managed AWS services.  
Raw JSON clickstream events are ingested, transformed, and stored as **partitioned Parquet data**, enabling efficient analytics with **Amazon Athena**.

The solution follows AWS best practices:
- Least-privilege IAM
- Idempotent ETL (Glue job bookmarks)
- Schema enforcement
- Partitioned S3 storage
- Logging and monitoring
- No hard-coded environment values

---

## Architecture (High Level)

1. **Kinesis Data Firehose** – Ingests JSON clickstream events  
2. **S3 (Raw Zone)** – Stores raw data partitioned by date  
3. **AWS Glue ETL Job** – Transforms JSON → Parquet  
4. **S3 (Processed Zone)** – Stores partitioned Parquet data  
5. **AWS Glue Crawler** – Catalogs processed data  
6. **Amazon Athena** – Queries transformed data  

---

## S3 Data Layout

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
│   ├── provider.tf
│   ├── main.tf
│   ├── data.tf
│   ├── s3.tf
│   ├── iam.tf
│   ├── firehose.tf
│   ├── glue.tf
│   ├── athena.tf
│   └── README.md
│
├── glue/
│   ├── transform_json_to_parquet.py
│   └── README.md
│
└── README.md
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
aws glue start-job-run --job-name clickstream-etl-<env>
```

---

## IAM Security Model

* Least-privilege IAM policy
* Scoped S3 read/write permissions
* CloudWatch logging access
* Explicit `iam:PassRole` for Glue

No wildcard permissions (`s3:*`, `glue:*`) are used.

---


---

## Outcome

This project demonstrates:

* Production-grade AWS ETL architecture
* Secure, scalable serverless design
* Strong Terraform and Glue expertise
* Optimized analytics using Athena

