# -----------------------------------------------------------------------------
# CloudTrail Module - Terraform Native Tests (Mocked Provider)
#
# Run with: terraform -chdir=modules/cloudtrail test
# No AWS credentials required.
# -----------------------------------------------------------------------------

mock_provider "aws" {}

variables {
  trail_name     = "lz-management-trail"
  s3_bucket_name = "lz-audit-logs-555500001111"
  s3_key_prefix  = "cloudtrail"

  is_multi_region_trail            = true
  include_global_service_events    = true
  enable_log_file_validation       = true
  enable_logging                   = true
  is_organization_trail            = false
  management_event_read_write_type = "All"

  tags = {
    Environment = "production"
    Project     = "landing-zone"
  }
}

# -----------------------------------------------------------------------------
# Test: Trail created
# -----------------------------------------------------------------------------

run "trail_created" {
  command = plan

  assert {
    condition     = aws_cloudtrail.this.name == "lz-management-trail"
    error_message = "Trail should have the specified name."
  }
}

# -----------------------------------------------------------------------------
# Test: Correct S3 bucket configured
# -----------------------------------------------------------------------------

run "s3_bucket_configured" {
  command = plan

  assert {
    condition     = aws_cloudtrail.this.s3_bucket_name == "lz-audit-logs-555500001111"
    error_message = "Trail should deliver to the specified S3 bucket."
  }

  assert {
    condition     = aws_cloudtrail.this.s3_key_prefix == "cloudtrail"
    error_message = "Trail should use the specified S3 key prefix."
  }
}

# -----------------------------------------------------------------------------
# Test: Multi-region default
# -----------------------------------------------------------------------------

run "multi_region_default" {
  command = plan

  assert {
    condition     = aws_cloudtrail.this.is_multi_region_trail == true
    error_message = "Trail should be multi-region by default."
  }
}

# -----------------------------------------------------------------------------
# Test: Global service events enabled
# -----------------------------------------------------------------------------

run "global_service_events" {
  command = plan

  assert {
    condition     = aws_cloudtrail.this.include_global_service_events == true
    error_message = "Trail should include global service events."
  }
}

# -----------------------------------------------------------------------------
# Test: Log file validation enabled
# -----------------------------------------------------------------------------

run "log_file_validation" {
  command = plan

  assert {
    condition     = aws_cloudtrail.this.enable_log_file_validation == true
    error_message = "Log file validation should be enabled by default."
  }
}

# -----------------------------------------------------------------------------
# Test: Logging enabled
# -----------------------------------------------------------------------------

run "logging_enabled" {
  command = plan

  assert {
    condition     = aws_cloudtrail.this.enable_logging == true
    error_message = "Logging should be enabled by default."
  }
}

# -----------------------------------------------------------------------------
# Test: Management events captured
# -----------------------------------------------------------------------------

run "management_events_captured" {
  command = plan

  assert {
    condition     = aws_cloudtrail.this.event_selector[0].include_management_events == true
    error_message = "Management events should be included."
  }

  assert {
    condition     = aws_cloudtrail.this.event_selector[0].read_write_type == "All"
    error_message = "Management events should capture All (read+write)."
  }
}

# -----------------------------------------------------------------------------
# Test: Optional prefix empty
# -----------------------------------------------------------------------------

run "prefix_empty" {
  command = plan

  variables {
    s3_key_prefix = ""
  }

  assert {
    condition     = aws_cloudtrail.this.s3_key_prefix == null
    error_message = "S3 key prefix should be null when empty."
  }
}

# -----------------------------------------------------------------------------
# Test: Optional SNS empty
# -----------------------------------------------------------------------------

run "sns_empty" {
  command = plan

  assert {
    condition     = aws_cloudtrail.this.sns_topic_name == null
    error_message = "SNS topic should be null when not specified."
  }
}

# -----------------------------------------------------------------------------
# Test: SNS configured when provided
# -----------------------------------------------------------------------------

run "sns_configured" {
  command = plan

  variables {
    sns_topic_name = "cloudtrail-notifications"
  }

  assert {
    condition     = aws_cloudtrail.this.sns_topic_name == "cloudtrail-notifications"
    error_message = "SNS topic should be set when provided."
  }
}

# -----------------------------------------------------------------------------
# Test: Organization trail disabled by default
# -----------------------------------------------------------------------------

run "org_trail_disabled" {
  command = plan

  assert {
    condition     = aws_cloudtrail.this.is_organization_trail == false
    error_message = "Organization trail should be disabled by default."
  }
}

# -----------------------------------------------------------------------------
# Test: Tags merged
# -----------------------------------------------------------------------------

run "tags_merged" {
  command = plan

  assert {
    condition     = aws_cloudtrail.this.tags["ManagedBy"] == "terraform"
    error_message = "Trail should have ManagedBy=terraform tag."
  }

  assert {
    condition     = aws_cloudtrail.this.tags["Component"] == "cloudtrail"
    error_message = "Trail should have Component=cloudtrail tag."
  }

  assert {
    condition     = aws_cloudtrail.this.tags["Environment"] == "production"
    error_message = "Trail should inherit caller Environment tag."
  }
}

# -----------------------------------------------------------------------------
# Test: Metadata output
# -----------------------------------------------------------------------------

run "metadata_output" {
  command = plan

  assert {
    condition     = output.cloudtrail_metadata.trail_name == "lz-management-trail"
    error_message = "Metadata should report trail name."
  }

  assert {
    condition     = output.cloudtrail_metadata.s3_bucket == "lz-audit-logs-555500001111"
    error_message = "Metadata should report S3 bucket."
  }

  assert {
    condition     = output.cloudtrail_metadata.is_multi_region == true
    error_message = "Metadata should report multi-region=true."
  }

  assert {
    condition     = output.cloudtrail_metadata.is_organization_trail == false
    error_message = "Metadata should report org trail=false."
  }

  assert {
    condition     = output.cloudtrail_metadata.management_event_type == "All"
    error_message = "Metadata should report management event type."
  }
}

# -----------------------------------------------------------------------------
# Test: WriteOnly management events
# -----------------------------------------------------------------------------

run "write_only_events" {
  command = plan

  variables {
    management_event_read_write_type = "WriteOnly"
  }

  assert {
    condition     = aws_cloudtrail.this.event_selector[0].read_write_type == "WriteOnly"
    error_message = "Should support WriteOnly management events."
  }
}

# -----------------------------------------------------------------------------
# Test: CloudWatch Logs enabled by default
# -----------------------------------------------------------------------------

run "cloudwatch_logs_enabled" {
  command = plan

  assert {
    condition     = length(aws_cloudwatch_log_group.trail) == 1
    error_message = "CloudWatch Log Group should be created by default."
  }

  assert {
    condition     = length(aws_iam_role.cloudtrail_cloudwatch) == 1
    error_message = "CloudWatch IAM role should be created by default."
  }

  assert {
    condition     = length(aws_kms_key.cloudwatch) == 1
    error_message = "KMS key should be created for CloudWatch Logs encryption."
  }

  assert {
    condition     = output.cloudtrail_metadata.cloudwatch_logs == true
    error_message = "Metadata should report cloudwatch_logs=true."
  }
}

# -----------------------------------------------------------------------------
# Test: CloudWatch Logs can be disabled
# -----------------------------------------------------------------------------

run "cloudwatch_logs_disabled" {
  command = plan

  variables {
    enable_cloudwatch_logs = false
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.trail) == 0
    error_message = "No CloudWatch Log Group when disabled."
  }

  assert {
    condition     = length(aws_iam_role.cloudtrail_cloudwatch) == 0
    error_message = "No IAM role when CloudWatch disabled."
  }

  assert {
    condition     = length(aws_kms_key.cloudwatch) == 0
    error_message = "No KMS key when CloudWatch disabled."
  }
}
