# -----------------------------------------------------------------------------
# GuardDuty Module - Main
#
# Creates an account-level GuardDuty detector with configurable protection
# features. This module is DETECTION only — no automated remediation.
#
# Scope:
# - Single-account detector enablement
# - Finding publishing frequency configuration
# - S3 protection (data plane event monitoring)
# - Kubernetes audit log monitoring
# - EBS malware protection
#
# NOT in scope:
# - Organization-wide administration / delegated administrator
# - Member account invitation
# - Finding export to S3
# - EventBridge rules for findings
# - Automated remediation
# -----------------------------------------------------------------------------

resource "aws_guardduty_detector" "this" {
  enable                       = var.enable
  finding_publishing_frequency = var.finding_publishing_frequency

  tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Component = "guardduty"
    },
  )
}

# -----------------------------------------------------------------------------
# Protection Features
#
# Using aws_guardduty_detector_feature resources (preferred over deprecated
# datasources block). Each feature can be independently enabled/disabled.
# -----------------------------------------------------------------------------

resource "aws_guardduty_detector_feature" "s3_data_events" {
  detector_id = aws_guardduty_detector.this.id
  name        = "S3_DATA_EVENTS"
  status      = var.enable_s3_protection ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "eks_audit_logs" {
  detector_id = aws_guardduty_detector.this.id
  name        = "EKS_AUDIT_LOGS"
  status      = var.enable_kubernetes_protection ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "ebs_malware_protection" {
  detector_id = aws_guardduty_detector.this.id
  name        = "EBS_MALWARE_PROTECTION"
  status      = var.enable_malware_protection ? "ENABLED" : "DISABLED"
}
