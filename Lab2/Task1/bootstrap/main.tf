# Separate bootstrap root: no backend dependency on the bucket it creates.
resource "aws_s3_bucket" "state" {
  #checkov:skip=CKV2_AWS_62:EX-013 Terraform state has no event consumer; notifications are not needed for locking.
  #checkov:skip=CKV_AWS_18:EX-014 A separate access-log bucket is not provisioned in this minimal bootstrap.
  #checkov:skip=CKV_AWS_144:EX-015 Cross-region replication needs extra buckets/IAM and is outside the lab scope.
  #checkov:skip=CKV_AWS_145:EX-016 SSE-S3 AES256 avoids unverified KMS permissions; encryption, TLS and versioning remain enabled.
  bucket        = var.state_bucket_name
  force_destroy = false

  tags = {
    Name    = var.state_bucket_name
    Purpose = "NT548-Lab2-Task1-Terraform-State"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "tls_only" {
  bucket = aws_s3_bucket.state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket     = aws_s3_bucket.state.id
  depends_on = [aws_s3_bucket_versioning.state]
  rule {
    id     = "state-history-and-incomplete-uploads"
    status = "Enabled"
    filter {}
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
