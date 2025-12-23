  GNU nano 8.3                                                                            s3.tf                                                                                       
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "raw" {
  bucket = "clickstream-raw-${random_id.suffix.hex}"

  tags = {
    Name        = "ClickstreamRaw"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "processed" {
  bucket = "clickstream-processed-${random_id.suffix.hex}"

  tags = {
    Name        = "ClickstreamProcessed"
    Environment = "Dev"
  }
}


