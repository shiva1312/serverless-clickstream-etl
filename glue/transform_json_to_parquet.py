from awsglue.context import GlueContext
from pyspark.context import SparkContext
from awsglue.transforms import *

sc = SparkContext()
glueContext = GlueContext(sc)


df = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    format="json",
    connection_options={"paths": ["s3://clickstream-raw-c2a7f5b3/"]}
)

cleaned = DropFields.apply(
    frame=df,
    paths=["ip_address", "user_agent"]
)


glueContext.write_dynamic_frame.from_options(
    frame=cleaned,
    connection_type="s3",
    format="parquet",
    connection_options={"path": "s3://clickstream-processed-c2a7f5b3/"}
)

