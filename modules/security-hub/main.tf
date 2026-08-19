# -----------------------------------------------------------------------------
# Security Hub Module - Main
#
# Enables AWS Security Hub at the account level and subscribes to configured
# security standards. This module is COMPLIANCE AGGREGATION only.
#
# Scope:
# - Account-level Security Hub enablement
# - Standards subscriptions (AWS FSBP, CIS, etc.)
# - Control disable overrides
#
# NOT in scope:
# - Organization-wide administration / delegated administrator
# - Member account enrollment
# - Cross-region aggregation
# - Central configuration
# - Finding export
# - Automated remediation
#
# Dependencies:
# - AWS Config must be enabled for security controls to produce findings.
#   This module does not enforce that dependency — it is the caller's
#   responsibility to enable Config in the same account/region.
# - GuardDuty findings flow to Security Hub automatically when both are
#   enabled in the same account/region.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Security Hub Account Enablement
# -----------------------------------------------------------------------------

resource "aws_securityhub_account" "this" {
  enable_default_standards = var.enable_default_standards
  auto_enable_controls     = var.auto_enable_controls
}

# -----------------------------------------------------------------------------
# Standards Subscriptions
#
# Only enabled standards are subscribed. The depends_on ensures Security Hub
# is active before attempting to subscribe to standards.
# -----------------------------------------------------------------------------

locals {
  enabled_standards = {
    for key, std in var.standards : key => std
    if std.enabled
  }
}

resource "aws_securityhub_standards_subscription" "this" {
  for_each = local.enabled_standards

  standards_arn = each.value.arn

  depends_on = [aws_securityhub_account.this]
}

# -----------------------------------------------------------------------------
# Control Overrides (Disable Specific Controls)
#
# Allows disabling individual controls within subscribed standards.
# Only use for controls with documented business justification.
#
# Uses aws_securityhub_standards_control_association which is the
# current non-deprecated approach for managing control status.
# -----------------------------------------------------------------------------

resource "aws_securityhub_standards_control_association" "disabled" {
  for_each = var.disabled_controls

  standards_arn       = each.value.standards_arn
  security_control_id = each.value.control_id
  association_status  = "DISABLED"
  updated_reason      = each.value.reason

  depends_on = [aws_securityhub_standards_subscription.this]
}
