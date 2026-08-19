# -----------------------------------------------------------------------------
# Identity Center Module - Outputs
# -----------------------------------------------------------------------------

output "permission_set_arns" {
  description = "Map of permission set key to ARN."
  value = {
    for key, ps in aws_ssoadmin_permission_set.this : key => ps.arn
  }
}

output "permission_set_names" {
  description = "Map of permission set key to name."
  value = {
    for key, ps in aws_ssoadmin_permission_set.this : key => ps.name
  }
}

output "assignment_ids" {
  description = "Map of assignment key to assignment identifier."
  value = {
    for key, a in aws_ssoadmin_account_assignment.this : key => a.id
  }
}

output "identity_center_metadata" {
  description = "Summary metadata about the Identity Center configuration."
  value = {
    instance_arn          = var.instance_arn
    permission_set_count  = length(var.permission_sets)
    assignment_count      = length(var.assignments)
    managed_policy_count  = length(local.managed_policy_attachments)
    customer_policy_count = length(local.customer_policy_attachments)
    inline_policy_count   = length(local.inline_policies)
  }
}
