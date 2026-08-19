# -----------------------------------------------------------------------------
# Log Archive Module - Variable Definitions
#
# Defines the public interface for a secure S3 log storage bucket
# designed for audit/security log retention.
# -----------------------------------------------------------------------------

variable "bucket_name" {
  description = "Name for the S3 log archive bucket."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be a valid S3 bucket name (3-63 chars, lowercase, no uppercase or underscores)."
  }
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning. Recommended for audit logs to prevent accidental deletion/overwrite."
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Server-side encryption type. Use 'AES256' for S3-managed keys or 'aws:kms' for KMS encryption."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_type)
    error_message = "Encryption type must be 'AES256' or 'aws:kms'."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for server-side encryption. Required when encryption_type is 'aws:kms'."
  type        = string
  default     = ""

  validation {
    condition     = var.kms_key_arn == "" || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/.+$", var.kms_key_arn))
    error_message = "KMS key ARN must be empty or a valid KMS key ARN."
  }
}

variable "force_destroy" {
  description = "Allow Terraform to destroy the bucket even if it contains objects. Set to false (default) for audit log safety."
  type        = bool
  default     = false
}

variable "transition_to_ia_days" {
  description = "Days before transitioning objects to Infrequent Access. Set to 0 to disable."
  type        = number
  default     = 90

  validation {
    condition     = var.transition_to_ia_days >= 0
    error_message = "Transition to IA days must be >= 0."
  }
}

variable "transition_to_glacier_days" {
  description = "Days before transitioning objects to Glacier. Set to 0 to disable. Must be > transition_to_ia_days if both are set."
  type        = number
  default     = 365

  validation {
    condition     = var.transition_to_glacier_days >= 0
    error_message = "Transition to Glacier days must be >= 0."
  }
}

variable "expiration_days" {
  description = "Days before objects expire (are deleted). Set to 0 to disable. Must be > transition_to_glacier_days if both set."
  type        = number
  default     = 2555

  validation {
    condition     = var.expiration_days >= 0
    error_message = "Expiration days must be >= 0."
  }
}

variable "cloudtrail_account_ids" {
  description = "List of AWS account IDs allowed to deliver CloudTrail logs to this bucket. Use [\"*\"] for any account in the organization (with org condition)."
  type        = list(string)
  default     = []
}

variable "organization_id" {
  description = "AWS Organization ID for bucket policy conditions. If provided, restricts access to accounts within this organization."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to all resources in this module."
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
