# -----------------------------------------------------------------------------
# CloudTrail Module - Main
#
# Creates an account-level CloudTrail trail for management event auditing.
#
# Scope:
# - Trail creation and configuration
# - Management event capture (read/write)
# - S3 delivery
# - Log file integrity validation
# - Multi-region coverage
#
# NOT in scope:
# - S3 bucket creation (use log-archive module)
# - Organization trail (future scope)
# - Data events (opt-in, high volume/cost)
# - CloudWatch Logs integration (future scope)
# - Automated alerting/response
#
# Dependencies:
# - S3 bucket must exist with CloudTrail delivery policy
# - Optional: KMS key for encryption
# - Optional: SNS topic for notifications
# -----------------------------------------------------------------------------

resource "aws_cloudtrail" "this" {
  name           = var.trail_name
  s3_bucket_name = var.s3_bucket_name
  s3_key_prefix  = var.s3_key_prefix != "" ? var.s3_key_prefix : null

  is_multi_region_trail         = var.is_multi_region_trail
  include_global_service_events = var.include_global_service_events
  enable_log_file_validation    = var.enable_log_file_validation
  enable_logging                = var.enable_logging
  is_organization_trail         = var.is_organization_trail

  sns_topic_name = var.sns_topic_name != "" ? var.sns_topic_name : null
  kms_key_id     = var.kms_key_id != "" ? var.kms_key_id : null

  event_selector {
    read_write_type           = var.management_event_read_write_type
    include_management_events = true
  }

  tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Component = "cloudtrail"
    },
  )
}
