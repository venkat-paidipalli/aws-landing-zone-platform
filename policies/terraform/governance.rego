# -----------------------------------------------------------------------------
# Governance Policies for Terraform Configurations
#
# These policies enforce landing zone governance standards.
# Run with: conftest test --policy policies/terraform/ <plan.json>
# -----------------------------------------------------------------------------
package terraform.governance

# Deny aws_controltower_* deployment resources in this portfolio
deny[msg] {
  resource := input.resource_changes[_]
  startswith(resource.type, "aws_controltower_")
  msg := sprintf("Control Tower resource %s is not permitted in this repository. CT integration is documentation-only.", [resource.address])
}

# Deny organization trails (is_organization_trail = true) without explicit approval
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_cloudtrail"
  resource.change.after.is_organization_trail == true
  msg := sprintf("Organization trail %s requires explicit approval. Account-level trails only in v1.", [resource.address])
}

# Warn on missing ManagedBy tag for trackable resources
warn[msg] {
  resource := input.resource_changes[_]
  resource.change.after.tags
  not resource.change.after.tags.ManagedBy
  trackable_type(resource.type)
  msg := sprintf("Resource %s is missing ManagedBy tag.", [resource.address])
}

trackable_type(t) { t == "aws_s3_bucket" }
trackable_type(t) { t == "aws_vpc" }
trackable_type(t) { t == "aws_subnet" }
trackable_type(t) { t == "aws_organizations_organizational_unit" }
trackable_type(t) { t == "aws_organizations_account" }
trackable_type(t) { t == "aws_guardduty_detector" }
