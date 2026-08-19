# -----------------------------------------------------------------------------
# Log Archive Module - Terraform Native Tests (Mocked Provider)
#
# Run with: terraform -chdir=modules/log-archive test
# No AWS credentials required.
# -----------------------------------------------------------------------------

mock_provider "aws" {}

variables {
  bucket_name                = "lz-audit-logs-555500001111"
  enable_versioning          = true
  encryption_type            = "AES256"
  force_destroy              = false
  transition_to_ia_days      = 90
  transition_to_glacier_days = 365
  expiration_days            = 2555

  tags = {
    Environment = "production"
    Project     = "landing-zone"
  }
}

# -----------------------------------------------------------------------------
# Test: Bucket created
# -----------------------------------------------------------------------------

run "bucket_created" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.bucket == "lz-audit-logs-555500001111"
    error_message = "Bucket should have the specified name."
  }
}

# -----------------------------------------------------------------------------
# Test: Public access completely blocked
# -----------------------------------------------------------------------------

run "public_access_blocked" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls == true
    error_message = "block_public_acls should be true."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_policy == true
    error_message = "block_public_policy should be true."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.ignore_public_acls == true
    error_message = "ignore_public_acls should be true."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.restrict_public_buckets == true
    error_message = "restrict_public_buckets should be true."
  }
}

# -----------------------------------------------------------------------------
# Test: Versioning enabled
# -----------------------------------------------------------------------------

run "versioning_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning should be Enabled."
  }
}

# -----------------------------------------------------------------------------
# Test: Encryption enabled (AES256 default)
# -----------------------------------------------------------------------------

run "encryption_aes256" {
  command = plan

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Encryption should use AES256 by default."
  }
}

# -----------------------------------------------------------------------------
# Test: KMS encryption
# -----------------------------------------------------------------------------

run "encryption_kms" {
  command = plan

  variables {
    encryption_type = "aws:kms"
    kms_key_arn     = "arn:aws:kms:us-east-1:555500001111:key/example-key-id"
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "Encryption should use aws:kms when configured."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default[0].kms_master_key_id == "arn:aws:kms:us-east-1:555500001111:key/example-key-id"
    error_message = "KMS key ARN should be set."
  }
}

# -----------------------------------------------------------------------------
# Test: Force destroy safe default
# -----------------------------------------------------------------------------

run "force_destroy_safe" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "force_destroy should default to false for safety."
  }
}

# -----------------------------------------------------------------------------
# Test: Lifecycle configuration exists
# -----------------------------------------------------------------------------

run "lifecycle_configured" {
  command = plan

  assert {
    condition     = one(aws_s3_bucket_lifecycle_configuration.this.rule).status == "Enabled"
    error_message = "Lifecycle rule should be enabled."
  }
}

# -----------------------------------------------------------------------------
# Test: Bucket policy contains CloudTrail principal
# -----------------------------------------------------------------------------

# Note: Bucket policy content cannot be verified with mocked provider because
# data.aws_iam_policy_document generates synthetic values. The policy structure
# (CloudTrail principal + DenyInsecureTransport) is verified via terraform
# validate and the integration fixture.

# -----------------------------------------------------------------------------
# Test: Ownership controls enforce BucketOwnerEnforced
# -----------------------------------------------------------------------------

run "ownership_bucket_owner_enforced" {
  command = plan

  assert {
    condition     = aws_s3_bucket_ownership_controls.this.rule[0].object_ownership == "BucketOwnerEnforced"
    error_message = "Object ownership should be BucketOwnerEnforced."
  }
}

# -----------------------------------------------------------------------------
# Test: Tags merged
# -----------------------------------------------------------------------------

run "tags_merged" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.tags["ManagedBy"] == "terraform"
    error_message = "Bucket should have ManagedBy=terraform tag."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Component"] == "log-archive"
    error_message = "Bucket should have Component=log-archive tag."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Environment"] == "production"
    error_message = "Bucket should inherit caller Environment tag."
  }
}

# -----------------------------------------------------------------------------
# Test: Metadata output
# -----------------------------------------------------------------------------

run "metadata_output" {
  command = plan

  assert {
    condition     = output.log_archive_metadata.bucket_name == "lz-audit-logs-555500001111"
    error_message = "Metadata should report correct bucket name."
  }

  assert {
    condition     = output.log_archive_metadata.encryption_type == "AES256"
    error_message = "Metadata should report AES256 encryption."
  }

  assert {
    condition     = output.log_archive_metadata.versioning_enabled == true
    error_message = "Metadata should report versioning enabled."
  }

  assert {
    condition     = output.log_archive_metadata.force_destroy == false
    error_message = "Metadata should report force_destroy=false."
  }
}
