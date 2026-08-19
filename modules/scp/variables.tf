# -----------------------------------------------------------------------------
# SCP Module - Variable Definitions
#
# Defines the public interface for managing Service Control Policies.
# Policies are defined as a map with logical names, and targets reference
# canonical OU paths resolved through a separate target_ids map.
# -----------------------------------------------------------------------------

variable "policies" {
  description = <<-EOT
    Map of Service Control Policies to create and attach.

    Map key: logical policy identifier (used in Terraform state and outputs).

    Object attributes:
    - name:        Display name for the SCP in AWS Organizations
    - description: Human-readable description of what the policy enforces
    - content:     The policy document JSON string
    - targets:     List of canonical OU paths or "ROOT" to attach this policy to
    - tags:        Optional tags to apply to the policy resource
  EOT
  type = map(object({
    name        = string
    description = string
    content     = string
    targets     = list(string)
    tags        = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, policy in var.policies :
      length(policy.name) >= 1 && length(policy.name) <= 128
    ])
    error_message = "Policy names must be between 1 and 128 characters."
  }

  validation {
    condition = alltrue([
      for key, policy in var.policies :
      length(policy.description) <= 512
    ])
    error_message = "Policy descriptions must not exceed 512 characters."
  }

  validation {
    condition = alltrue([
      for key, policy in var.policies :
      length(policy.content) >= 1
    ])
    error_message = "Policy content must not be empty."
  }

  validation {
    condition = alltrue([
      for key, policy in var.policies :
      length(policy.targets) >= 1
    ])
    error_message = "Each policy must have at least one target."
  }

  validation {
    condition = alltrue([
      for key, policy in var.policies :
      alltrue([
        for target in policy.targets :
        contains(keys(var.target_ids), target)
      ])
    ])
    error_message = "All policy targets must exist in the target_ids map."
  }

  validation {
    condition = alltrue([
      for key, policy in var.policies :
      alltrue([
        for tag_key, _ in policy.tags :
        !startswith(tag_key, "aws:")
      ])
    ])
    error_message = "Tag keys must not use the reserved 'aws:' prefix."
  }

  validation {
    condition = alltrue([
      for key, policy in var.policies :
      alltrue([
        for tag_key, tag_value in policy.tags :
        length(tag_key) >= 1 && length(tag_key) <= 128 && length(tag_value) <= 256
      ])
    ])
    error_message = "Tag keys must be 1-128 characters and tag values must not exceed 256 characters."
  }
}

variable "target_ids" {
  description = <<-EOT
    Map of canonical target path to AWS Organizations target ID.

    This decouples the SCP module from the organization module. The caller
    provides the mapping between logical OU paths and actual AWS OU/root IDs.

    Example:
    {
      "ROOT"              = "r-ab12"
      "Security"          = "ou-ab12-security"
      "Infrastructure"    = "ou-ab12-infra"
      "Workloads/NonProd" = "ou-ab12-nonprod"
      "Workloads/Prod"    = "ou-ab12-prod"
      "Sandbox"           = "ou-ab12-sandbox"
      "Suspended"         = "ou-ab12-suspended"
    }
  EOT
  type        = map(string)

  validation {
    condition = alltrue([
      for path, id in var.target_ids :
      length(id) >= 1
    ])
    error_message = "All target IDs must be non-empty strings."
  }
}
