# -----------------------------------------------------------------------------
# SCP Module - Outputs
# -----------------------------------------------------------------------------

output "policy_ids" {
  description = "Map of policy logical key to AWS policy ID."
  value = {
    for key, policy in aws_organizations_policy.this : key => policy.id
  }
}

output "policy_arns" {
  description = "Map of policy logical key to AWS policy ARN."
  value = {
    for key, policy in aws_organizations_policy.this : key => policy.arn
  }
}

output "policy_attachment_targets" {
  description = "Map of attachment key (policy:target) to target ID."
  value = {
    for key, attachment in aws_organizations_policy_attachment.this :
    key => attachment.target_id
  }
}

output "policy_metadata" {
  description = "Summary metadata about the SCP configuration."
  value = {
    policy_count     = length(var.policies)
    attachment_count = length(local.policy_attachments)
    target_paths     = distinct(flatten([for _, p in var.policies : p.targets]))
  }
}
