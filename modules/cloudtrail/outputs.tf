# -----------------------------------------------------------------------------
# CloudTrail Module - Outputs
# -----------------------------------------------------------------------------

output "trail_id" {
  description = "The ID of the CloudTrail trail."
  value       = aws_cloudtrail.this.id
}

output "trail_arn" {
  description = "The ARN of the CloudTrail trail."
  value       = aws_cloudtrail.this.arn
}

output "trail_name" {
  description = "The name of the CloudTrail trail."
  value       = aws_cloudtrail.this.name
}

output "trail_home_region" {
  description = "The home region of the trail."
  value       = aws_cloudtrail.this.home_region
}

output "multi_region_enabled" {
  description = "Whether the trail is multi-region."
  value       = aws_cloudtrail.this.is_multi_region_trail
}

output "log_file_validation_enabled" {
  description = "Whether log file integrity validation is enabled."
  value       = aws_cloudtrail.this.enable_log_file_validation
}

output "cloudtrail_metadata" {
  description = "Summary metadata about the CloudTrail configuration."
  value = {
    trail_name            = var.trail_name
    s3_bucket             = var.s3_bucket_name
    s3_key_prefix         = var.s3_key_prefix
    is_multi_region       = var.is_multi_region_trail
    include_global_events = var.include_global_service_events
    log_file_validation   = var.enable_log_file_validation
    logging_enabled       = var.enable_logging
    is_organization_trail = var.is_organization_trail
    management_event_type = var.management_event_read_write_type
    sns_enabled           = var.sns_topic_name != ""
    kms_enabled           = var.kms_key_id != ""
  }
}
