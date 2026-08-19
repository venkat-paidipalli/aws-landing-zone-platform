# -----------------------------------------------------------------------------
# SCP Module - Main
#
# Creates Service Control Policies and attaches them to specified targets.
#
# Design:
# - Policies are created with for_each over var.policies
# - Attachments are flattened from policy×target combinations
# - Target resolution uses var.target_ids (OU path → AWS ID)
# - No implicit root attachment — all targets must be explicitly configured
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Locals - Flatten policy-target combinations into attachment map
# -----------------------------------------------------------------------------

locals {
  # Create a flat map of all policy-target attachment pairs.
  # Key format: "{policy_key}:{target_path}" for deterministic, readable keys.
  policy_attachments = merge([
    for policy_key, policy in var.policies : {
      for target in policy.targets :
      "${policy_key}:${target}" => {
        policy_key  = policy_key
        target_path = target
        target_id   = var.target_ids[target]
      }
    }
  ]...)
}

# -----------------------------------------------------------------------------
# Service Control Policies
# -----------------------------------------------------------------------------

resource "aws_organizations_policy" "this" {
  for_each = var.policies

  name        = each.value.name
  description = each.value.description
  content     = each.value.content
  type        = "SERVICE_CONTROL_POLICY"

  tags = merge(
    each.value.tags,
    {
      ManagedBy = "terraform"
      PolicyKey = each.key
    },
  )
}

# -----------------------------------------------------------------------------
# Policy Attachments
#
# Each policy is attached to its specified targets. Targets are resolved
# through the target_ids map, which maps canonical OU paths to AWS IDs.
#
# Safety: No implicit root attachment. Every target must be explicitly
# specified in the policy configuration.
# -----------------------------------------------------------------------------

resource "aws_organizations_policy_attachment" "this" {
  for_each = local.policy_attachments

  policy_id = aws_organizations_policy.this[each.value.policy_key].id
  target_id = each.value.target_id
}
