import sys
import logging

from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql.types import StructType, StructField, StringType

logger = logging.getLogger("clickstream-etl")
logger.setLevel(logging.INFO)

args = getResolvedOptions(sys.argv, ["JOB_NAME", "SOURCE_S3", "TARGET_S3"])

source_path = args["SOURCE_S3"].rstrip("/") + "/"
target_path = args["TARGET_S3"].rstrip("/") + "/"
quarantine_path = f"{target_path}_quarantine/"

sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session

job = Job(glue_context)
job.init(args["JOB_NAME"], args)


def empty(df) -> bool:
    # cheap-ish emptiness check without a full count on huge data
    return df.rdd.isEmpty()


try:
    logger.info("clickstream ETL starting")
    logger.info("reading from %s", source_path)
    logger.info("writing to %s", target_path)

    # Clickstream JSON is often messy; keep schema simple and parse timestamps ourselves.
    schema = StructType([
        StructField("event_time", StringType(), True),
        StructField("user_id", StringType(), True),
        StructField("event_type", StringType(), True),
        StructField("page", StringType(), True),
        StructField("ip_address", StringType(), True),
        StructField("user_agent", StringType(), True),
    ])

    raw = spark.read.schema(schema).json(source_path)

    if empty(raw):
        logger.warning("no new data found; exiting")
        job.commit()
        sys.exit(0)

    # Parse timestamp; anything that doesn't parse goes to quarantine.
    parsed = (
        raw.withColumn("event_time_ts", F.to_timestamp("event_time"))
           .withColumn("ingest_ts", F.current_timestamp())
    )

    bad = parsed.filter(F.col("event_time_ts").isNull())
    good = parsed.filter(F.col("event_time_ts").isNotNull())

    bad_count = bad.count()
    good_count = good.count()

    logger.info("good records: %d", good_count)
    logger.info("bad records: %d", bad_count)

    out = (
        good.drop("ip_address", "user_agent")
            .drop("event_time")
            .withColumnRenamed("event_time_ts", "event_time")
            .withColumn("year", F.year("event_time"))
            .withColumn("month", F.month("event_time"))
            .withColumn("day", F.dayofmonth("event_time"))
    )

    (out.write
        .mode("append")
        .partitionBy("year", "month", "day")
        .parquet(target_path))

    if bad_count > 0:
        (bad.withColumn("quarantine_reason", F.lit("invalid_or_missing_event_time"))
            .write.mode("append").parquet(quarantine_path))
        logger.warning("wrote bad records to %s", quarantine_path)

    logger.info("clickstream ETL finished ok")
    job.commit()

except Exception:
    logger.exception("clickstream ETL failed")
    raise
