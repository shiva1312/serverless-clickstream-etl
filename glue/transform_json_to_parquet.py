
import sys
import logging
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql.types import StructType, StructField, StringType, TimestampType


# Logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# Arguments (NO hardcoding)

args = getResolvedOptions(
    sys.argv,
    ["JOB_NAME", "RAW_BUCKET", "PROCESSED_BUCKET"]
)

RAW_BUCKET = args["RAW_BUCKET"]
PROCESSED_BUCKET = args["PROCESSED_BUCKET"]


# Glue Context

sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session

job = Job(glue_context)
job.init(args["JOB_NAME"], args)

try:
    logger.info("Starting Glue clickstream ETL job")

    
    # Explicit schema
    
    schema = StructType([
        StructField("event_time", TimestampType(), True),
        StructField("user_id", StringType(), True),
        StructField("event_type", StringType(), True),
        StructField("page", StringType(), True),
        StructField("ip_address", StringType(), True),
        StructField("user_agent", StringType(), True)
    ])

    
    # Read JSON (job bookmarks enabled)
    
    df = spark.read.schema(schema).json(f"s3://{RAW_BUCKET}/")

    if df.rdd.isEmpty():
        logger.warning("No new data found. Exiting.")
        job.commit()
        sys.exit(0)

    
    # Transform + partition columns
    
    transformed_df = (
        df.drop("ip_address", "user_agent")
          .withColumn("year", F.year("event_time"))
          .withColumn("month", F.month("event_time"))
          .withColumn("day", F.dayofmonth("event_time"))
    )

    
    # Write Parquet (partitioned)

    transformed_df.write \
        .mode("append") \
        .partitionBy("year", "month", "day") \
        .parquet(f"s3://{PROCESSED_BUCKET}/")

    logger.info("Glue ETL job completed successfully")
    job.commit()

except Exception as e:
    logger.error("Glue job failed", exc_info=True)
    raise
