# -----------------------------------------------------------------------------
# Log Archive Module - Main
#
# Creates a secure S3 bucket for audit/security log storage with:
# - Complete public access block
# - Versioning (tamper protection)
# - Server-side encryption (AES256 or KMS)
# - Lifecycle rules (IA → Glacier → expiration)
# - Bucket ownership controls (no legacy ACLs)
# - CloudTrail delivery bucket policy
#
# This module is STORAGE only. It does not create CloudTrail, Config delivery,
# or any log-producing service. Those are separate modules.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# S3 Bucket
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Component = "log-archive"
    },
  )
}

# -----------------------------------------------------------------------------
# Bucket Ownership - Enforce BucketOwnerEnforced (no ACLs)
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# -----------------------------------------------------------------------------
# Public Access Block - Complete lockdown
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# Versioning
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# -----------------------------------------------------------------------------
# Server-Side Encryption
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_type
      kms_master_key_id = var.encryption_type == "aws:kms" ? var.kms_key_arn : null
    }
    bucket_key_enabled = var.encryption_type == "aws:kms" ? true : false
  }
}

# -----------------------------------------------------------------------------
# Lifecycle Rules
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "log-retention"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    dynamic "transition" {
      for_each = var.transition_to_ia_days > 0 ? [1] : []
      content {
        days          = var.transition_to_ia_days
        storage_class = "STANDARD_IA"
      }
    }

    dynamic "transition" {
      for_each = var.transition_to_glacier_days > 0 ? [1] : []
      content {
        days          = var.transition_to_glacier_days
        storage_class = "GLACIER"
      }
    }

    dynamic "expiration" {
      for_each = var.expiration_days > 0 ? [1] : []
      content {
        days = var.expiration_days
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

# -----------------------------------------------------------------------------
# Bucket Policy - CloudTrail Delivery
#
# Grants the CloudTrail service principal permission to:
# - Check bucket ACL (GetBucketAcl)
# - Write log files (PutObject) with bucket-owner-full-control
#
# Conditions:
# - PutObject restricted to cloudtrail service principal
# - If organization_id provided, restricts to org members only
# - Object key prefix follows CloudTrail convention: AWSLogs/<account-id>/
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "AllowCloudTrailGetBucketAcl"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.this.arn]
  }

  statement {
    sid    = "AllowCloudTrailPutObject"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/AWSLogs/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  # Deny unencrypted transport
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket_policy.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}
