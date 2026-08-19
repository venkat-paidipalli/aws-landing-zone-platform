# -----------------------------------------------------------------------------
# Organization Module - Outputs
# -----------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Organization
# ---------------------------------------------------------------------------

output "organization_id" {
  description = "The ID of the AWS Organization."
  value       = aws_organizations_organization.this.id
}

output "organization_arn" {
  description = "The ARN of the AWS Organization."
  value       = aws_organizations_organization.this.arn
}

output "root_id" {
  description = "The ID of the organization root."
  value       = local.root_id
}

# ---------------------------------------------------------------------------
# Organizational Units
# ---------------------------------------------------------------------------

output "organizational_unit_ids" {
  description = "Map of OU path to OU ID."
  value       = local.ou_id_map
}

output "organizational_unit_arns" {
  description = "Map of OU path to OU ARN."
  value       = local.ou_arn_map
}

# ---------------------------------------------------------------------------
# Accounts
# ---------------------------------------------------------------------------

output "account_ids" {
  description = "Map of account logical key to AWS account ID."
  value = {
    for key, acct in aws_organizations_account.this : key => acct.id
  }
}

output "account_arns" {
  description = "Map of account logical key to account ARN."
  value = {
    for key, acct in aws_organizations_account.this : key => acct.arn
  }
}

output "account_parent_map" {
  description = "Map of account logical key to parent OU ID."
  value = {
    for key, acct in aws_organizations_account.this : key => acct.parent_id
  }
}

# ---------------------------------------------------------------------------
# Computed / Debug Outputs
# ---------------------------------------------------------------------------

output "organization_metadata" {
  description = "Summary metadata about the organization configuration."
  value = {
    name          = var.organization_name
    feature_set   = var.feature_set
    ou_count      = length(var.organizational_units)
    account_count = length(var.accounts)
  }
}
