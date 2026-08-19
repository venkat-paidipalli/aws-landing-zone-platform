# -----------------------------------------------------------------------------
# GuardDuty Module - Terraform Native Tests (Mocked Provider)
#
# Validates GuardDuty module logic without AWS API calls.
# Run with: terraform -chdir=modules/guardduty test
# No AWS credentials required.
# -----------------------------------------------------------------------------

mock_provider "aws" {}

# -----------------------------------------------------------------------------
# Variables shared across test runs (production-like defaults)
# -----------------------------------------------------------------------------

variables {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  enable_s3_protection         = true
  enable_kubernetes_protection = false
  enable_malware_protection    = false

  tags = {
    Environment = "production"
    Project     = "landing-zone"
  }
}

# -----------------------------------------------------------------------------
# Test: Detector created and enabled
# -----------------------------------------------------------------------------

run "detector_created" {
  command = plan

  assert {
    condition     = aws_guardduty_detector.this.enable == true
    error_message = "Detector should be enabled."
  }
}

# -----------------------------------------------------------------------------
# Test: Detector enabled by default
# -----------------------------------------------------------------------------

run "detector_enabled_by_default" {
  command = plan

  assert {
    condition     = output.detector_enabled == true
    error_message = "Detector should be enabled by default."
  }
}

# -----------------------------------------------------------------------------
# Test: Detector can be disabled
# -----------------------------------------------------------------------------

run "detector_can_be_disabled" {
  command = plan

  variables {
    enable = false
  }

  assert {
    condition     = aws_guardduty_detector.this.enable == false
    error_message = "Detector should be disabled when enable=false."
  }

  assert {
    condition     = output.detector_enabled == false
    error_message = "Output should reflect disabled state."
  }
}

# -----------------------------------------------------------------------------
# Test: Default publishing frequency
# -----------------------------------------------------------------------------

run "default_publishing_frequency" {
  command = plan

  assert {
    condition     = aws_guardduty_detector.this.finding_publishing_frequency == "FIFTEEN_MINUTES"
    error_message = "Default publishing frequency should be FIFTEEN_MINUTES."
  }
}

# -----------------------------------------------------------------------------
# Test: Custom publishing frequency
# -----------------------------------------------------------------------------

run "custom_publishing_frequency" {
  command = plan

  variables {
    finding_publishing_frequency = "SIX_HOURS"
  }

  assert {
    condition     = aws_guardduty_detector.this.finding_publishing_frequency == "SIX_HOURS"
    error_message = "Publishing frequency should be configurable to SIX_HOURS."
  }
}

# -----------------------------------------------------------------------------
# Test: S3 protection enabled by default
# -----------------------------------------------------------------------------

run "s3_protection_enabled" {
  command = plan

  assert {
    condition     = aws_guardduty_detector_feature.s3_data_events.name == "S3_DATA_EVENTS"
    error_message = "S3 feature should have name S3_DATA_EVENTS."
  }

  assert {
    condition     = aws_guardduty_detector_feature.s3_data_events.status == "ENABLED"
    error_message = "S3 protection should be ENABLED by default."
  }
}

# -----------------------------------------------------------------------------
# Test: Kubernetes protection disabled by default
# -----------------------------------------------------------------------------

run "kubernetes_protection_disabled_by_default" {
  command = plan

  assert {
    condition     = aws_guardduty_detector_feature.eks_audit_logs.name == "EKS_AUDIT_LOGS"
    error_message = "EKS feature should have name EKS_AUDIT_LOGS."
  }

  assert {
    condition     = aws_guardduty_detector_feature.eks_audit_logs.status == "DISABLED"
    error_message = "Kubernetes protection should be DISABLED by default."
  }
}

# -----------------------------------------------------------------------------
# Test: Malware protection disabled by default
# -----------------------------------------------------------------------------

run "malware_protection_disabled_by_default" {
  command = plan

  assert {
    condition     = aws_guardduty_detector_feature.ebs_malware_protection.name == "EBS_MALWARE_PROTECTION"
    error_message = "Malware feature should have name EBS_MALWARE_PROTECTION."
  }

  assert {
    condition     = aws_guardduty_detector_feature.ebs_malware_protection.status == "DISABLED"
    error_message = "Malware protection should be DISABLED by default."
  }
}

# -----------------------------------------------------------------------------
# Test: All features can be enabled
# -----------------------------------------------------------------------------

run "all_features_enabled" {
  command = plan

  variables {
    enable_s3_protection         = true
    enable_kubernetes_protection = true
    enable_malware_protection    = true
  }

  assert {
    condition     = aws_guardduty_detector_feature.s3_data_events.status == "ENABLED"
    error_message = "S3 protection should be ENABLED."
  }

  assert {
    condition     = aws_guardduty_detector_feature.eks_audit_logs.status == "ENABLED"
    error_message = "Kubernetes protection should be ENABLED when requested."
  }

  assert {
    condition     = aws_guardduty_detector_feature.ebs_malware_protection.status == "ENABLED"
    error_message = "Malware protection should be ENABLED when requested."
  }
}

# -----------------------------------------------------------------------------
# Test: Features can be disabled
# -----------------------------------------------------------------------------

run "all_features_disabled" {
  command = plan

  variables {
    enable_s3_protection         = false
    enable_kubernetes_protection = false
    enable_malware_protection    = false
  }

  assert {
    condition     = aws_guardduty_detector_feature.s3_data_events.status == "DISABLED"
    error_message = "S3 protection should be DISABLED when requested."
  }

  assert {
    condition     = aws_guardduty_detector_feature.eks_audit_logs.status == "DISABLED"
    error_message = "Kubernetes protection should be DISABLED."
  }

  assert {
    condition     = aws_guardduty_detector_feature.ebs_malware_protection.status == "DISABLED"
    error_message = "Malware protection should be DISABLED."
  }
}

# -----------------------------------------------------------------------------
# Test: Tags merged correctly
# -----------------------------------------------------------------------------

run "tags_merged" {
  command = plan

  assert {
    condition     = aws_guardduty_detector.this.tags["ManagedBy"] == "terraform"
    error_message = "Detector should have ManagedBy=terraform tag."
  }

  assert {
    condition     = aws_guardduty_detector.this.tags["Component"] == "guardduty"
    error_message = "Detector should have Component=guardduty tag."
  }

  assert {
    condition     = aws_guardduty_detector.this.tags["Environment"] == "production"
    error_message = "Detector should inherit caller-provided Environment tag."
  }

  assert {
    condition     = aws_guardduty_detector.this.tags["Project"] == "landing-zone"
    error_message = "Detector should inherit caller-provided Project tag."
  }
}

# -----------------------------------------------------------------------------
# Test: Enabled features output
# -----------------------------------------------------------------------------

run "enabled_features_output" {
  command = plan

  assert {
    condition     = output.enabled_features.s3_protection == true
    error_message = "enabled_features should report s3_protection=true."
  }

  assert {
    condition     = output.enabled_features.kubernetes_protection == false
    error_message = "enabled_features should report kubernetes_protection=false."
  }

  assert {
    condition     = output.enabled_features.malware_protection == false
    error_message = "enabled_features should report malware_protection=false."
  }
}

# -----------------------------------------------------------------------------
# Test: Metadata output correct
# -----------------------------------------------------------------------------

run "metadata_output" {
  command = plan

  assert {
    condition     = output.guardduty_metadata.detector_enabled == true
    error_message = "Metadata should report detector_enabled=true."
  }

  assert {
    condition     = output.guardduty_metadata.finding_publishing_frequency == "FIFTEEN_MINUTES"
    error_message = "Metadata should report correct frequency."
  }

  assert {
    condition     = output.guardduty_metadata.s3_protection == true
    error_message = "Metadata should report s3_protection=true."
  }
}
