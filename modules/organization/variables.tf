# -----------------------------------------------------------------------------
# Organization Module - Variable Definitions
#
# Domain model for an AWS Organization including organizational units and
# member accounts. This file defines the public interface and validation
# contract for the module.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Organization Metadata
# -----------------------------------------------------------------------------

variable "organization_name" {
  description = "Logical name for this organization (used in tagging and naming conventions, not an AWS API field)."
  type        = string

  validation {
    condition     = length(var.organization_name) >= 2 && length(var.organization_name) <= 64
    error_message = "Organization name must be between 2 and 64 characters."
  }

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.organization_name))
    error_message = "Organization name must start with a lowercase letter, end with a letter or digit, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "feature_set" {
  description = "AWS Organizations feature set. ALL enables SCPs and advanced features. CONSOLIDATED_BILLING enables billing only."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "CONSOLIDATED_BILLING"], var.feature_set)
    error_message = "Feature set must be either 'ALL' or 'CONSOLIDATED_BILLING'."
  }
}

# -----------------------------------------------------------------------------
# Organizational Units
# -----------------------------------------------------------------------------

variable "organizational_units" {
  description = <<-EOT
    Map of organizational units to create. The map key is the canonical OU path.

    OU Path Convention:
    - "Security"          -> top-level OU under Root
    - "Workloads/NonProd" -> nested OU "NonProd" under "Workloads"
    - ROOT is the implicit parent for top-level OUs (never specified in path)
    - Paths use "/" as separator
    - No leading or trailing slashes
    - Parent OUs must also be defined in this map

    Object attributes:
    - name:        Display name for the OU (defaults to last segment of path)
    - parent:      Parent path ("ROOT" for top-level, or another OU path)
    - description: Human-readable description of the OU's purpose
    - tags:        Map of tags to apply to the OU
  EOT
  type = map(object({
    name        = optional(string)
    parent      = string
    description = optional(string, "")
    tags        = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for path, ou in var.organizational_units :
      length(path) >= 1 && length(path) <= 128
    ])
    error_message = "OU paths must be between 1 and 128 characters."
  }

  validation {
    condition = alltrue([
      for path, ou in var.organizational_units :
      !startswith(path, "/") && !endswith(path, "/")
    ])
    error_message = "OU paths must not start or end with '/'."
  }

  validation {
    condition = alltrue([
      for path, ou in var.organizational_units :
      !can(regex("//", path))
    ])
    error_message = "OU paths must not contain consecutive slashes '//'."
  }

  validation {
    condition = alltrue([
      for path, ou in var.organizational_units :
      contains(["ROOT"], ou.parent) || contains(keys(var.organizational_units), ou.parent)
    ])
    error_message = "Each OU parent must be 'ROOT' or reference another OU path defined in this map."
  }

  validation {
    condition = alltrue([
      for path, ou in var.organizational_units :
      alltrue([
        for key, _ in ou.tags :
        !startswith(key, "aws:")
      ])
    ])
    error_message = "Tag keys must not use the reserved 'aws:' prefix."
  }

  validation {
    condition = alltrue([
      for path, ou in var.organizational_units :
      alltrue([
        for key, value in ou.tags :
        length(key) >= 1 && length(key) <= 128 && length(value) <= 256
      ])
    ])
    error_message = "Tag keys must be 1-128 characters and tag values must not exceed 256 characters."
  }
}

# -----------------------------------------------------------------------------
# Accounts
# -----------------------------------------------------------------------------

variable "accounts" {
  description = <<-EOT
    Map of member accounts to create within the organization. The map key is a
    logical identifier used for referencing the account in Terraform.

    Object attributes:
    - name:      AWS account name (appears in the console)
    - email:     Unique email for the account root user
    - ou_path:   OU path where this account should be placed
    - role_name: IAM role name for cross-account access from management
    - tags:      Map of tags to apply to the account
  EOT
  type = map(object({
    name      = string
    email     = string
    ou_path   = string
    role_name = optional(string, "OrganizationAccountAccessRole")
    tags      = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, acct in var.accounts :
      length(acct.name) >= 1 && length(acct.name) <= 50
    ])
    error_message = "Account names must be between 1 and 50 characters."
  }

  validation {
    condition = alltrue([
      for key, acct in var.accounts :
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*$", acct.name))
    ])
    error_message = "Account names must start with an alphanumeric character and contain only letters, digits, dots, hyphens, or underscores."
  }

  validation {
    condition     = length(distinct([for key, acct in var.accounts : acct.name])) == length(var.accounts)
    error_message = "Account names must be unique across all accounts."
  }

  validation {
    condition = alltrue([
      for key, acct in var.accounts :
      can(regex("^[^@]+@[^@]+\\.[^@]+$", acct.email))
    ])
    error_message = "Account emails must be syntactically valid (user@domain.tld format)."
  }

  validation {
    condition     = length(distinct([for key, acct in var.accounts : acct.email])) == length(var.accounts)
    error_message = "Account emails must be unique across all accounts."
  }

  validation {
    condition = alltrue([
      for key, acct in var.accounts :
      contains(keys(var.organizational_units), acct.ou_path)
    ])
    error_message = "Each account ou_path must reference a valid OU path defined in organizational_units."
  }

  validation {
    condition = alltrue([
      for key, acct in var.accounts :
      can(regex("^[a-zA-Z_][a-zA-Z0-9_+=,.@-]{0,63}$", acct.role_name))
    ])
    error_message = "Role names must be valid IAM role names: start with a letter or underscore, 1-64 characters, containing letters, digits, and +=,.@- characters."
  }

  validation {
    condition = alltrue([
      for key, acct in var.accounts :
      alltrue([
        for tag_key, _ in acct.tags :
        !startswith(tag_key, "aws:")
      ])
    ])
    error_message = "Tag keys must not use the reserved 'aws:' prefix."
  }

  validation {
    condition = alltrue([
      for key, acct in var.accounts :
      alltrue([
        for tag_key, tag_value in acct.tags :
        length(tag_key) >= 1 && length(tag_key) <= 128 && length(tag_value) <= 256
      ])
    ])
    error_message = "Tag keys must be 1-128 characters and tag values must not exceed 256 characters."
  }
}
