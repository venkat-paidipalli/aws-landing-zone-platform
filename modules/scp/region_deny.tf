# -----------------------------------------------------------------------------
# Region Deny Policy - Dynamic Generation
#
# Generates the region-restriction SCP content dynamically based on
# var.approved_regions. This allows callers to configure which regions
# are permitted without modifying static JSON.
#
# Global services (IAM, Organizations, Route53, CloudFront, etc.) are
# excluded from region restrictions because they operate globally and
# would break if denied in non-approved regions.
# -----------------------------------------------------------------------------

variable "approved_regions" {
  description = <<-EOT
    List of AWS regions that are approved for use. Actions in non-approved
    regions will be denied by the generated region-restriction policy.

    If empty, no region-deny policy content is generated (output will be
    an empty string).

    Example: ["us-east-1", "us-west-2"]
  EOT
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for region in var.approved_regions :
      can(regex("^[a-z]{2}(-[a-z]+-\\d+|global)$", region))
    ])
    error_message = "Each approved region must be a valid AWS region format (e.g., 'us-east-1', 'eu-west-1')."
  }
}

locals {
  # AWS services that operate globally and must be excluded from
  # region-based restrictions. Denying these in non-approved regions
  # would break fundamental AWS functionality.
  global_service_actions = [
    "a4b:*",
    "access-analyzer:*",
    "account:*",
    "budgets:*",
    "ce:*",
    "chatbot:*",
    "cloudfront:*",
    "cur:*",
    "globalaccelerator:*",
    "health:*",
    "iam:*",
    "importexport:*",
    "organizations:*",
    "route53:*",
    "route53domains:*",
    "shield:*",
    "sts:*",
    "support:*",
    "trustedadvisor:*",
    "waf:*",
    "wafv2:*",
    "wellarchitected:*",
  ]

  # Generate the region-deny policy document only if regions are specified.
  region_deny_policy_content = length(var.approved_regions) > 0 ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnapprovedRegions"
        Effect    = "Deny"
        NotAction = local.global_service_actions
        Resource  = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = var.approved_regions
          }
        }
      }
    ]
  }) : ""
}

output "region_deny_policy_content" {
  description = "Generated JSON policy document for region restriction. Empty if no approved_regions specified."
  value       = local.region_deny_policy_content
}
