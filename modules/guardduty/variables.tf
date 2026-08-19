# -----------------------------------------------------------------------------
# GuardDuty Module - Variable Definitions
#
# Defines the public interface for an account-level GuardDuty detector baseline.
# This module enables threat detection only — no automated remediation.
# -----------------------------------------------------------------------------

variable "enable" {
  description = "Whether to enable the GuardDuty detector. Set to false to suspend without destroying."
  type        = bool
  default     = true
}

variable "finding_publishing_frequency" {
  description = <<-EOT
    Frequency for publishing updated findings to CloudWatch Events and S3.
    Allowed values: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS.

    Default is FIFTEEN_MINUTES for rapid threat visibility. Use SIX_HOURS
    for cost optimization in non-production environments.
  EOT
  type        = string
  default     = "FIFTEEN_MINUTES"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "Finding publishing frequency must be one of: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS."
  }
}

# -----------------------------------------------------------------------------
# Protection Features
# -----------------------------------------------------------------------------

variable "enable_s3_protection" {
  description = "Enable S3 data event protection (monitors S3 data plane events for threats)."
  type        = bool
  default     = true
}

variable "enable_kubernetes_protection" {
  description = "Enable Kubernetes audit log monitoring (detects threats in EKS clusters)."
  type        = bool
  default     = false
}

variable "enable_malware_protection" {
  description = "Enable EBS malware protection (scans EBS volumes attached to potentially compromised instances)."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to the GuardDuty detector resource."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key, _ in var.tags :
      !startswith(key, "aws:")
    ])
    error_message = "Tag keys must not use the reserved 'aws:' prefix."
  }

  validation {
    condition = alltrue([
      for key, value in var.tags :
      length(key) >= 1 && length(key) <= 128 && length(value) <= 256
    ])
    error_message = "Tag keys must be 1-128 characters and tag values must not exceed 256 characters."
  }
}
