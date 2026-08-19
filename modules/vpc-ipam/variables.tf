# -----------------------------------------------------------------------------
# VPC IPAM Module - Variable Definitions
#
# Defines the public interface for centralized IP address management.
# Supports a top-level IPAM with configurable child pools.
# -----------------------------------------------------------------------------

variable "operating_regions" {
  description = "List of AWS regions for IPAM operation. At least one required."
  type        = list(string)

  validation {
    condition     = length(var.operating_regions) >= 1
    error_message = "At least one operating region must be specified."
  }

  validation {
    condition = alltrue([
      for region in var.operating_regions :
      can(regex("^[a-z]{2}-[a-z]+-\\d+$", region))
    ])
    error_message = "Each operating region must be a valid AWS region (e.g., 'us-east-1')."
  }
}

variable "description" {
  description = "Description for the IPAM instance."
  type        = string
  default     = "Landing zone centralized IP address management"
}

variable "pools" {
  description = <<-EOT
    Map of IPAM pools to create under the top-level IPAM.

    Map key: logical pool identifier.

    Object attributes:
    - description:    Human-readable description
    - locale:         Region for the pool (must be an operating region)
    - cidrs:          List of CIDRs to provision in this pool
    - tags:           Optional tags
  EOT
  type = map(object({
    description = optional(string, "")
    locale      = optional(string, "")
    cidrs       = list(string)
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, pool in var.pools :
      length(pool.cidrs) >= 1
    ])
    error_message = "Each pool must have at least one CIDR."
  }

  validation {
    condition = alltrue([
      for key, pool in var.pools :
      alltrue([
        for cidr in pool.cidrs :
        can(cidrhost(cidr, 0))
      ])
    ])
    error_message = "Each pool CIDR must be a valid IPv4 CIDR."
  }

  validation {
    condition = alltrue([
      for key, pool in var.pools :
      alltrue([for tk, _ in pool.tags : !startswith(tk, "aws:")])
    ])
    error_message = "Pool tag keys must not use the reserved 'aws:' prefix."
  }
}

variable "tags" {
  description = "Tags applied to the IPAM and all pools."
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
