# -----------------------------------------------------------------------------
# Organization Module - Main
#
# Creates and manages:
# - AWS Organization
# - Organizational Units (up to 2 levels: top-level + one nested level)
# - Member accounts with OU placement
#
# Design decisions:
# - OUs are split into top-level (parent=ROOT) and nested (parent=another OU)
#   to ensure Terraform resolves dependencies correctly.
# - Accounts include lifecycle protection against accidental deletion.
# - The management account is NOT created here (it exists before the org).
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Organization
# -----------------------------------------------------------------------------

resource "aws_organizations_organization" "this" {
  feature_set = var.feature_set

  # Service access principals are enabled incrementally as each service module
  # is implemented. Do not enable principals for services not yet configured.
  # Future additions: cloudtrail, config, guardduty, securityhub, sso, etc.
  aws_service_access_principals = []

  # SERVICE_CONTROL_POLICY is required for SCP enforcement (implemented).
  # Additional policy types (TAG_POLICY, etc.) will be enabled when their
  # respective governance modules are implemented.
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
  ]
}

# -----------------------------------------------------------------------------
# Locals - OU Resolution
# -----------------------------------------------------------------------------

locals {
  # Derive the organization root ID from the organization resource.
  root_id = aws_organizations_organization.this.roots[0].id

  # Split OUs into top-level (parent = ROOT) and nested (parent = another OU).
  # This two-pass approach ensures top-level OUs exist before nested ones
  # reference them, without requiring complex dependency graphs.
  top_level_ous = {
    for path, ou in var.organizational_units : path => ou
    if ou.parent == "ROOT"
  }

  nested_ous = {
    for path, ou in var.organizational_units : path => ou
    if ou.parent != "ROOT"
  }

  # Compute display name for each OU (last segment of path if not specified).
  ou_display_names = {
    for path, ou in var.organizational_units : path =>
    coalesce(ou.name, element(split("/", path), length(split("/", path)) - 1))
  }

  # Build a unified map of OU path -> OU ID for account placement.
  # Combines top-level and nested OU IDs into one lookup table.
  ou_id_map = merge(
    { for path, ou in aws_organizations_organizational_unit.top_level : path => ou.id },
    { for path, ou in aws_organizations_organizational_unit.nested : path => ou.id },
  )

  # Build a unified map of OU path -> OU ARN.
  ou_arn_map = merge(
    { for path, ou in aws_organizations_organizational_unit.top_level : path => ou.arn },
    { for path, ou in aws_organizations_organizational_unit.nested : path => ou.arn },
  )
}

# -----------------------------------------------------------------------------
# Organizational Units - Top Level (parent = ROOT)
# -----------------------------------------------------------------------------

resource "aws_organizations_organizational_unit" "top_level" {
  for_each = local.top_level_ous

  name      = local.ou_display_names[each.key]
  parent_id = local.root_id

  tags = merge(
    each.value.tags,
    {
      ManagedBy = "terraform"
      OUPath    = each.key
    },
  )
}

# -----------------------------------------------------------------------------
# Organizational Units - Nested (parent = another OU)
#
# Limitation (v1): This supports exactly one level of nesting (e.g.,
# "Workloads/NonProd" where "Workloads" is top-level). For deeper nesting
# (3+ levels), additional resource blocks or a recursive module pattern
# would be required. AWS allows up to 5 levels of OU nesting.
#
# This is documented and acceptable for the current landing zone design
# which uses only 2 levels.
# -----------------------------------------------------------------------------

resource "aws_organizations_organizational_unit" "nested" {
  for_each = local.nested_ous

  name      = local.ou_display_names[each.key]
  parent_id = aws_organizations_organizational_unit.top_level[each.value.parent].id

  tags = merge(
    each.value.tags,
    {
      ManagedBy = "terraform"
      OUPath    = each.key
    },
  )

  depends_on = [aws_organizations_organizational_unit.top_level]
}

# -----------------------------------------------------------------------------
# Member Accounts
#
# Safety considerations:
# - close_on_deletion = false prevents Terraform destroy from closing accounts.
#   When false, destroying the resource only REMOVES the account from the org
#   (it becomes a standalone account) rather than permanently closing it.
# - lifecycle.prevent_destroy adds a second layer of protection: Terraform
#   will refuse to plan a destroy of these resources entirely.
# - iam_user_access_to_billing defaults to "ALLOW" per AWS convention.
#
# What happens on `terraform destroy`:
# - With close_on_deletion=false: account is removed from the organization
#   but NOT closed. It becomes a standalone AWS account.
# - With prevent_destroy=true: Terraform refuses to destroy entirely.
#   You must remove prevent_destroy first (intentional friction).
# -----------------------------------------------------------------------------

resource "aws_organizations_account" "this" {
  for_each = var.accounts

  name                       = each.value.name
  email                      = each.value.email
  role_name                  = each.value.role_name
  parent_id                  = local.ou_id_map[each.value.ou_path]
  close_on_deletion          = false
  iam_user_access_to_billing = "ALLOW"

  tags = merge(
    each.value.tags,
    {
      ManagedBy   = "terraform"
      AccountKey  = each.key
      Environment = lookup(each.value.tags, "Environment", "unspecified")
    },
  )

  lifecycle {
    prevent_destroy = true

    # Email and name changes require careful handling. AWS does not allow
    # changing account email via Organizations API after creation.
    ignore_changes = [email]
  }
}
