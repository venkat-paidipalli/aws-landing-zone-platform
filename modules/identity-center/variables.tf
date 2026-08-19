# -----------------------------------------------------------------------------
# Identity Center Module - Variable Definitions
#
# Manages permission sets and account assignments for IAM Identity Center.
# Does NOT create users, groups, or configure external identity providers.
# -----------------------------------------------------------------------------

variable "instance_arn" {
  description = "ARN of the IAM Identity Center instance."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:sso:::instance/ssoins-", var.instance_arn))
    error_message = "Instance ARN must be a valid IAM Identity Center instance ARN (arn:aws:sso:::instance/ssoins-...)."
  }
}

# -----------------------------------------------------------------------------
# Permission Sets
# -----------------------------------------------------------------------------

variable "permission_sets" {
  description = <<-EOT
    Map of permission sets to create.

    Map key: logical identifier for Terraform referencing.

    Object attributes:
    - name:                     Display name (unique within instance)
    - description:              Human-readable description
    - session_duration:         ISO-8601 duration (e.g., PT1H, PT4H, PT8H)
    - relay_state:              Optional relay state URL
    - aws_managed_policies:     List of AWS managed policy ARNs to attach
    - customer_managed_policies: List of customer managed policy references
    - inline_policy:            Optional inline policy JSON string
    - tags:                     Optional tags
  EOT
  type = map(object({
    name                 = string
    description          = optional(string, "")
    session_duration     = optional(string, "PT1H")
    relay_state          = optional(string, "")
    aws_managed_policies = optional(list(string), [])
    customer_managed_policies = optional(list(object({
      name = string
      path = optional(string, "/")
    })), [])
    inline_policy = optional(string, "")
    tags          = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, ps in var.permission_sets :
      length(ps.name) >= 1 && length(ps.name) <= 32
    ])
    error_message = "Permission set names must be between 1 and 32 characters."
  }

  validation {
    condition = alltrue([
      for key, ps in var.permission_sets :
      can(regex("^PT[0-9]+[HM]$", ps.session_duration))
    ])
    error_message = "Session duration must be ISO-8601 format (e.g., PT1H, PT4H, PT30M)."
  }

  validation {
    condition = alltrue([
      for key, ps in var.permission_sets :
      alltrue([
        for arn in ps.aws_managed_policies :
        can(regex("^arn:aws:iam::aws:policy/", arn))
      ])
    ])
    error_message = "AWS managed policy ARNs must start with 'arn:aws:iam::aws:policy/'."
  }

  validation {
    condition = alltrue([
      for key, ps in var.permission_sets :
      ps.inline_policy == "" || can(jsondecode(ps.inline_policy))
    ])
    error_message = "Inline policy must be empty or valid JSON."
  }

  validation {
    condition = alltrue([
      for key, ps in var.permission_sets :
      alltrue([for tk, _ in ps.tags : !startswith(tk, "aws:")])
    ])
    error_message = "Tag keys must not use the reserved 'aws:' prefix."
  }
}

# -----------------------------------------------------------------------------
# Account Assignments
# -----------------------------------------------------------------------------

variable "assignments" {
  description = <<-EOT
    Map of account assignments linking permission sets to principals in accounts.

    Map key: unique logical identifier for each assignment.

    Object attributes:
    - permission_set_key: Key from the permission_sets map
    - principal_id:       ID of the user or group principal
    - principal_type:     "GROUP" or "USER"
    - target_account_id:  AWS account ID to assign access to
  EOT
  type = map(object({
    permission_set_key = string
    principal_id       = string
    principal_type     = string
    target_account_id  = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, a in var.assignments :
      contains(["GROUP", "USER"], a.principal_type)
    ])
    error_message = "Principal type must be 'GROUP' or 'USER'."
  }

  validation {
    condition = alltrue([
      for key, a in var.assignments :
      can(regex("^[0-9]{12}$", a.target_account_id))
    ])
    error_message = "Target account ID must be a 12-digit AWS account ID."
  }

  validation {
    condition = alltrue([
      for key, a in var.assignments :
      length(a.principal_id) >= 1
    ])
    error_message = "Principal ID must be non-empty."
  }

  validation {
    condition = alltrue([
      for key, a in var.assignments :
      contains(keys(var.permission_sets), a.permission_set_key)
    ])
    error_message = "Each assignment permission_set_key must reference a key in permission_sets."
  }
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Common tags applied to all permission sets."
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
