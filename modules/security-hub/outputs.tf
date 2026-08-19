# -----------------------------------------------------------------------------
# Security Hub Module - Outputs
# -----------------------------------------------------------------------------

output "security_hub_enabled" {
  description = "Whether Security Hub is enabled in this account."
  value       = true # Resource existence implies enablement
}

output "enabled_standards" {
  description = "Map of enabled standard keys to their ARNs."
  value = {
    for key, sub in aws_securityhub_standards_subscription.this :
    key => sub.standards_arn
  }
}

output "standard_subscription_arns" {
  description = "List of all active standard subscription ARNs."
  value = [
    for sub in aws_securityhub_standards_subscription.this :
    sub.standards_arn
  ]
}

output "disabled_controls" {
  description = "Map of disabled control overrides."
  value = {
    for key, ctrl in aws_securityhub_standards_control_association.disabled :
    key => {
      standards_arn = ctrl.standards_arn
      control_id    = ctrl.security_control_id
      status        = ctrl.association_status
    }
  }
}

output "security_hub_metadata" {
  description = "Summary metadata about the Security Hub configuration."
  value = {
    enable_default_standards = var.enable_default_standards
    auto_enable_controls     = var.auto_enable_controls
    standards_count          = length(local.enabled_standards)
    disabled_controls_count  = length(var.disabled_controls)
  }
}
