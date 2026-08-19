# -----------------------------------------------------------------------------
# Identity Center Module - Main
#
# Creates IAM Identity Center permission sets and account assignments.
#
# Scope:
# - Permission set creation and configuration
# - AWS managed policy attachments
# - Customer managed policy attachments
# - Inline policy attachments
# - Account assignments (principal → permission set → account)
#
# NOT in scope:
# - User/group creation (callers provide principal IDs)
# - External IdP configuration (SAML, OIDC)
# - SCIM provisioning
# - Identity Center instance creation
# - Delegated administration
# - Control Tower integration
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Permission Sets
# -----------------------------------------------------------------------------

resource "aws_ssoadmin_permission_set" "this" {
  for_each = var.permission_sets

  name             = each.value.name
  description      = each.value.description != "" ? each.value.description : "Managed by Terraform"
  instance_arn     = var.instance_arn
  session_duration = each.value.session_duration
  relay_state      = each.value.relay_state != "" ? each.value.relay_state : null

  tags = merge(
    var.tags,
    each.value.tags,
    {
      ManagedBy        = "terraform"
      Component        = "identity-center"
      PermissionSetKey = each.key
    },
  )
}

# -----------------------------------------------------------------------------
# AWS Managed Policy Attachments
# -----------------------------------------------------------------------------

locals {
  managed_policy_attachments = merge([
    for ps_key, ps in var.permission_sets : {
      for policy_arn in ps.aws_managed_policies :
      "${ps_key}:${replace(policy_arn, "/.*\\//", "")}" => {
        permission_set_key = ps_key
        policy_arn         = policy_arn
      }
    }
  ]...)
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = local.managed_policy_attachments

  instance_arn       = var.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set_key].arn
  managed_policy_arn = each.value.policy_arn
}

# -----------------------------------------------------------------------------
# Customer Managed Policy Attachments
# -----------------------------------------------------------------------------

locals {
  customer_policy_attachments = merge([
    for ps_key, ps in var.permission_sets : {
      for cp in ps.customer_managed_policies :
      "${ps_key}:${cp.name}" => {
        permission_set_key = ps_key
        policy_name        = cp.name
        policy_path        = cp.path
      }
    }
  ]...)
}

resource "aws_ssoadmin_customer_managed_policy_attachment" "this" {
  for_each = local.customer_policy_attachments

  instance_arn       = var.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set_key].arn

  customer_managed_policy_reference {
    name = each.value.policy_name
    path = each.value.policy_path
  }
}

# -----------------------------------------------------------------------------
# Inline Policies
# -----------------------------------------------------------------------------

locals {
  inline_policies = {
    for ps_key, ps in var.permission_sets : ps_key => ps.inline_policy
    if ps.inline_policy != ""
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  for_each = local.inline_policies

  instance_arn       = var.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
  inline_policy      = each.value
}

# -----------------------------------------------------------------------------
# Account Assignments
# -----------------------------------------------------------------------------

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = var.assignments

  instance_arn       = var.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set_key].arn

  principal_id   = each.value.principal_id
  principal_type = each.value.principal_type

  target_id   = each.value.target_account_id
  target_type = "AWS_ACCOUNT"
}
