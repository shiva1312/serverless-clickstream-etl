import sys
import logging

from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql.types import StructType, StructField, StringType

# -------------------------------------------------------------------
# Logging
# -------------------------------------------------------------------
logger = logging.getLogger("clickstream-etl")
logger.setLevel(logging.INFO)

# -------------------------------------------------------------------
args = getResolvedOptions(
    sys.argv,
    ["JOB_NAME", "SOURCE_S3", "TARGET_S3"]
)

source_path = args["SOURCE_S3"].rstrip("/") + "/"
target_path = args["TARGET_S3"].rstrip("/") + "/"
quarantine_path = f"{target_path}_quarantine/"

# -------------------------------------------------------------------
# Glue / Spark context (Glue-managed SparkContext)
# -------------------------------------------------------------------
sc = SparkContext.getOrCreate()
glue_context = GlueContext(sc)
spark = glue_context.spark_session

job = Job(glue_context)
job.init(args["JOB_NAME"], args)

# -------------------------------------------------------------------
# Utility: lightweight emptiness check (bookmark-friendly)
# -------------------------------------------------------------------
def is_empty(df) -> bool:
    return len(df.take(1)) == 0

# -------------------------------------------------------------------
# ETL
# -------------------------------------------------------------------
try:
    logger.info("Clickstream ETL job started")
    logger.info("Source path: %s", source_path)
    logger.info("Target path: %s", target_path)

    # Explicit schema for stability
    schema = StructType([
        StructField("event_time", StringType(), True),
        StructField("user_id", StringType(), True),
        StructField("event_type", StringType(), True),
        StructField("page", StringType(), True),
        StructField("ip_address", StringType(), True),
        StructField("user_agent", StringType(), True),
    ])

    raw_df = spark.read.schema(schema).json(source_path)

    if is_empty(raw_df):
        logger.warning("No new data found. Exiting gracefully.")
        job.commit()
        sys.exit(0)

    parsed_df = (
        raw_df
        .withColumn("event_time_ts", F.to_timestamp("event_time"))
        .withColumn("ingest_ts", F.current_timestamp())
    )

    bad_df = parsed_df.filter(F.col("event_time_ts").isNull())
    good_df = parsed_df.filter(F.col("event_time_ts").isNotNull())

    # Cache once to avoid repeated scans
    bad_df.cache()
    good_df.cache()

    logger.info("Good records: %d", good_df.count())
    logger.info("Bad records: %d", bad_df.count())

    curated_df = (
        good_df
        .drop("ip_address", "user_agent", "event_time")
        .withColumnRenamed("event_time_ts", "event_time")
        .withColumn("year", F.date_format("event_time", "yyyy"))
        .withColumn("month", F.date_format("event_time", "MM"))
        .withColumn("day", F.date_format("event_time", "dd"))
    )

    (
        curated_df.write
        .mode("append")
        .partitionBy("year", "month", "day")
        .parquet(target_path)
    )

    if not is_empty(bad_df):
        (
            bad_df
            .withColumn("quarantine_reason", F.lit("invalid_or_missing_event_time"))
            .write
            .mode("append")
            .parquet(quarantine_path)
        )
        logger.warning("Bad records written to quarantine path: %s", quarantine_path)

    logger.info("Clickstream ETL job completed successfully")
    job.commit()

except Exception:
    logger.exception("Clickstream ETL job failed")
    raise
