# -----------------------------------------------------------------------------
# Security Hub Module - Variable Definitions
#
# Defines the public interface for account-level Security Hub enablement.
# Supports standards subscriptions and optional control overrides.
# -----------------------------------------------------------------------------

variable "enable_default_standards" {
  description = <<-EOT
    Whether Security Hub automatically enables its default standards on
    activation. Set to false to manage standards explicitly via the
    standards variable.

    When true, AWS enables default standards (typically AWS Foundational
    Security Best Practices). When false, only standards listed in the
    'standards' variable will be enabled.
  EOT
  type        = bool
  default     = false
}

variable "auto_enable_controls" {
  description = "Whether to automatically enable new controls for subscribed standards."
  type        = bool
  default     = true
}

variable "standards" {
  description = <<-EOT
    Map of security standards to subscribe to.

    Map key: logical identifier for Terraform referencing.

    Object attributes:
    - arn: The ARN of the standard to subscribe to.
           Format: arn:aws:securityhub:<region>::standards/<standard-path>
           Common standards:
           - AWS Foundational: arn:aws:securityhub:<region>::standards/aws-foundational-security-best-practices/v/1.0.0
           - CIS 1.2: arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0
           - CIS 1.4: arn:aws:securityhub:<region>::standards/cis-aws-foundations-benchmark/v/1.4.0
    - enabled: Whether this standard subscription is active.
  EOT
  type = map(object({
    arn     = string
    enabled = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, std in var.standards :
      can(regex("^arn:aws:securityhub:", std.arn))
    ])
    error_message = "Each standard ARN must begin with 'arn:aws:securityhub:'."
  }

  validation {
    condition = alltrue([
      for key, std in var.standards :
      length(std.arn) >= 20
    ])
    error_message = "Standard ARNs must be non-empty valid ARN strings."
  }
}

variable "disabled_controls" {
  description = <<-EOT
    Map of Security Hub controls to disable.

    Map key: a unique logical identifier for each override.

    Object attributes:
    - standards_arn: The ARN of the standard containing the control.
    - control_id:   The control identifier (e.g., "IAM.1", "S3.1").
    - reason:       Reason for disabling (for documentation/audit).

    Only disable controls with clear business justification.
  EOT
  type = map(object({
    standards_arn = string
    control_id    = string
    reason        = optional(string, "Disabled by platform configuration")
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, ctrl in var.disabled_controls :
      can(regex("^arn:aws:securityhub:", ctrl.standards_arn))
    ])
    error_message = "Each standards_arn in disabled_controls must begin with 'arn:aws:securityhub:'."
  }

  validation {
    condition = alltrue([
      for key, ctrl in var.disabled_controls :
      length(ctrl.control_id) >= 1
    ])
    error_message = "Control IDs must be non-empty strings."
  }
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags applied to Security Hub resources where supported."
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
