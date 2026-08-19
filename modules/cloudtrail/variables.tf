# -----------------------------------------------------------------------------
# CloudTrail Module - Variable Definitions
#
# Defines the public interface for an account-level CloudTrail baseline.
# Captures management API events and delivers to S3.
# -----------------------------------------------------------------------------

variable "trail_name" {
  description = "Name for the CloudTrail trail."
  type        = string

  validation {
    condition     = length(var.trail_name) >= 3 && length(var.trail_name) <= 128
    error_message = "Trail name must be between 3 and 128 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_.-]*$", var.trail_name))
    error_message = "Trail name must start with a letter and contain only letters, digits, periods, hyphens, or underscores."
  }
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail log delivery. Must already exist with appropriate bucket policy."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.s3_bucket_name))
    error_message = "S3 bucket name must be a valid bucket name (3-63 chars, lowercase)."
  }
}

variable "s3_key_prefix" {
  description = "Optional S3 key prefix for CloudTrail log objects."
  type        = string
  default     = ""

  validation {
    condition     = length(var.s3_key_prefix) <= 200
    error_message = "S3 key prefix must not exceed 200 characters."
  }
}

variable "is_multi_region_trail" {
  description = "Whether the trail captures events from all regions. Recommended true for security visibility."
  type        = bool
  default     = true
}

variable "include_global_service_events" {
  description = "Whether to include global service events (IAM, STS). Should be true for at least one trail."
  type        = bool
  default     = true
}

variable "enable_log_file_validation" {
  description = "Enable log file integrity validation. Recommended true for tamper detection."
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Whether the trail is actively logging. Set to false to pause without destroying."
  type        = bool
  default     = true
}

variable "is_organization_trail" {
  description = "Whether this is an organization-level trail. Requires Organizations trusted access. Default false for account-level."
  type        = bool
  default     = false
}

variable "sns_topic_name" {
  description = "Optional SNS topic name for CloudTrail notifications. Leave empty to disable."
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "Optional KMS key ARN for CloudTrail log encryption. Leave empty for S3 bucket default encryption."
  type        = string
  default     = ""
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs integration for real-time trail event delivery."
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_retention" {
  description = "CloudWatch Log Group retention in days. 0 = never expire."
  type        = number
  default     = 90

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_log_group_retention)
    error_message = "Retention must be a valid CloudWatch Logs retention value."
  }
}

variable "management_event_read_write_type" {
  description = "Type of management events to log. ALL captures both read and write. ReadOnly or WriteOnly for selective capture."
  type        = string
  default     = "All"

  validation {
    condition     = contains(["All", "ReadOnly", "WriteOnly"], var.management_event_read_write_type)
    error_message = "Management event type must be 'All', 'ReadOnly', or 'WriteOnly'."
  }
}

variable "tags" {
  description = "Tags applied to the CloudTrail trail."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key, _ in var.tags :
      !startswith(key, "aws:")
    ])
    error_message = "Tag keys must not use the reserved 'aws:' prefix."
  }
}
