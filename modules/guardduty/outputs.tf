# -----------------------------------------------------------------------------
# GuardDuty Module - Outputs
# -----------------------------------------------------------------------------

output "detector_id" {
  description = "The ID of the GuardDuty detector."
  value       = aws_guardduty_detector.this.id
}

output "detector_arn" {
  description = "The ARN of the GuardDuty detector."
  value       = aws_guardduty_detector.this.arn
}

output "detector_enabled" {
  description = "Whether the detector is currently enabled."
  value       = aws_guardduty_detector.this.enable
}

output "enabled_features" {
  description = "Map of protection features and their enabled status."
  value = {
    s3_protection         = var.enable_s3_protection
    kubernetes_protection = var.enable_kubernetes_protection
    malware_protection    = var.enable_malware_protection
  }
}

output "guardduty_metadata" {
  description = "Summary metadata about the GuardDuty configuration."
  value = {
    detector_enabled             = var.enable
    finding_publishing_frequency = var.finding_publishing_frequency
    s3_protection                = var.enable_s3_protection
    kubernetes_protection        = var.enable_kubernetes_protection
    malware_protection           = var.enable_malware_protection
  }
}
