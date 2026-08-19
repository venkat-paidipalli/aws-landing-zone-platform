# -----------------------------------------------------------------------------
# Config Module - Variable Definitions
#
# Defines the public interface for an AWS Config governance baseline.
# Supports configuration recorder, delivery channel, and managed rules.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Recorder Configuration
# -----------------------------------------------------------------------------

variable "recorder_name" {
  description = "Name for the AWS Config configuration recorder."
  type        = string
  default     = "default"

  validation {
    condition     = length(var.recorder_name) >= 1 && length(var.recorder_name) <= 256
    error_message = "Recorder name must be between 1 and 256 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]*$", var.recorder_name))
    error_message = "Recorder name must start with a letter and contain only letters, digits, hyphens, or underscores."
  }
}

variable "recorder_role_arn" {
  description = "ARN of the IAM role that AWS Config uses to access resources and deliver logs."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.recorder_role_arn))
    error_message = "Recorder role ARN must be a valid IAM role ARN (arn:aws:iam::<account-id>:role/<role-name>)."
  }
}

variable "recording_all_resources" {
  description = "Whether to record all supported resource types. If false, use selected_resource_types."
  type        = bool
  default     = true
}

variable "selected_resource_types" {
  description = "List of specific resource types to record when recording_all_resources is false. Ignored when recording_all_resources is true."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for rt in var.selected_resource_types :
      can(regex("^AWS::", rt))
    ])
    error_message = "Each selected resource type must start with 'AWS::' (e.g., 'AWS::EC2::Instance')."
  }
}

variable "include_global_resource_types" {
  description = "Whether to include global resource types (IAM) in recording. Recommended true in one region only."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Delivery Channel Configuration
# -----------------------------------------------------------------------------

variable "delivery_channel_name" {
  description = "Name for the AWS Config delivery channel."
  type        = string
  default     = "default"

  validation {
    condition     = length(var.delivery_channel_name) >= 1 && length(var.delivery_channel_name) <= 256
    error_message = "Delivery channel name must be between 1 and 256 characters."
  }
}

variable "delivery_s3_bucket" {
  description = "Name of the S3 bucket for Config delivery. The bucket must already exist (not created by this module)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.delivery_s3_bucket))
    error_message = "S3 bucket name must be a valid bucket name (3-63 chars, lowercase, no uppercase or underscores)."
  }
}

variable "delivery_s3_key_prefix" {
  description = "Optional S3 key prefix for Config delivery objects."
  type        = string
  default     = ""

  validation {
    condition     = length(var.delivery_s3_key_prefix) <= 256
    error_message = "S3 key prefix must not exceed 256 characters."
  }
}

variable "delivery_sns_topic_arn" {
  description = "Optional SNS topic ARN for Config delivery notifications. Leave empty to disable."
  type        = string
  default     = ""

  validation {
    condition     = var.delivery_sns_topic_arn == "" || can(regex("^arn:aws:sns:[a-z0-9-]+:[0-9]{12}:.+$", var.delivery_sns_topic_arn))
    error_message = "SNS topic ARN must be empty or a valid SNS ARN (arn:aws:sns:<region>:<account-id>:<topic-name>)."
  }
}

variable "snapshot_delivery_frequency" {
  description = "Frequency for Config snapshot delivery to S3."
  type        = string
  default     = "TwentyFour_Hours"

  validation {
    condition = contains([
      "One_Hour",
      "Three_Hours",
      "Six_Hours",
      "Twelve_Hours",
      "TwentyFour_Hours",
    ], var.snapshot_delivery_frequency)
    error_message = "Snapshot frequency must be one of: One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours."
  }
}

# -----------------------------------------------------------------------------
# Managed Config Rules
# -----------------------------------------------------------------------------

variable "managed_rules" {
  description = <<-EOT
    Map of AWS-managed Config rules to create.

    Map key: logical rule identifier for Terraform referencing.

    Object attributes:
    - name:              Display name for the Config rule
    - source_identifier: AWS Config managed rule identifier (e.g., S3_BUCKET_PUBLIC_READ_PROHIBITED)
    - description:       Human-readable description
    - input_parameters:  Optional map of rule parameters
    - maximum_execution_frequency: Optional evaluation frequency for periodic rules
    - tags:              Optional tags
  EOT
  type = map(object({
    name                        = string
    source_identifier           = string
    description                 = optional(string, "")
    input_parameters            = optional(map(string), {})
    maximum_execution_frequency = optional(string, "")
    tags                        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, rule in var.managed_rules :
      length(rule.name) >= 1 && length(rule.name) <= 128
    ])
    error_message = "Rule names must be between 1 and 128 characters."
  }

  validation {
    condition = alltrue([
      for key, rule in var.managed_rules :
      can(regex("^[A-Z][A-Z0-9_]+$", rule.source_identifier))
    ])
    error_message = "Source identifiers must be uppercase with underscores (e.g., S3_BUCKET_PUBLIC_READ_PROHIBITED)."
  }

  validation {
    condition = alltrue([
      for key, rule in var.managed_rules :
      rule.maximum_execution_frequency == "" || contains([
        "One_Hour",
        "Three_Hours",
        "Six_Hours",
        "Twelve_Hours",
        "TwentyFour_Hours",
      ], rule.maximum_execution_frequency)
    ])
    error_message = "If specified, maximum_execution_frequency must be one of: One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours."
  }

  validation {
    condition = alltrue([
      for key, rule in var.managed_rules :
      alltrue([
        for tag_key, _ in rule.tags :
        !startswith(tag_key, "aws:")
      ])
    ])
    error_message = "Tag keys must not use the reserved 'aws:' prefix."
  }
}

# -----------------------------------------------------------------------------
# Common Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Common tags applied to all resources created by this module."
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
