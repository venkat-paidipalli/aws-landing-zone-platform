# -----------------------------------------------------------------------------
# Security Hub Module - Terraform Native Tests (Mocked Provider)
#
# Validates Security Hub module logic without AWS API calls.
# Run with: terraform -chdir=modules/security-hub test
# No AWS credentials required.
# -----------------------------------------------------------------------------

mock_provider "aws" {}

# -----------------------------------------------------------------------------
# Variables shared across test runs
# -----------------------------------------------------------------------------

variables {
  enable_default_standards = false
  auto_enable_controls     = true

  standards = {
    aws_foundational = {
      arn = "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
    }
    cis_1_4 = {
      arn     = "arn:aws:securityhub:us-east-1::standards/cis-aws-foundations-benchmark/v/1.4.0"
      enabled = true
    }
  }

  disabled_controls = {
    disable_cloudtrail_5 = {
      standards_arn = "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
      control_id    = "CloudTrail.5"
      reason        = "Multi-region trail managed by organization CloudTrail module"
    }
  }

  tags = {
    Environment = "production"
    Project     = "landing-zone"
  }
}

# -----------------------------------------------------------------------------
# Test: Security Hub account enabled
# -----------------------------------------------------------------------------

run "account_enabled" {
  command = plan

  assert {
    condition     = aws_securityhub_account.this.enable_default_standards == false
    error_message = "Security Hub should have enable_default_standards=false."
  }

  assert {
    condition     = aws_securityhub_account.this.auto_enable_controls == true
    error_message = "Security Hub should have auto_enable_controls=true."
  }
}

# -----------------------------------------------------------------------------
# Test: Security Hub enabled output
# -----------------------------------------------------------------------------

run "enabled_output" {
  command = plan

  assert {
    condition     = output.security_hub_enabled == true
    error_message = "security_hub_enabled output should be true."
  }
}

# -----------------------------------------------------------------------------
# Test: Default standards subscribed
# -----------------------------------------------------------------------------

run "standards_subscribed" {
  command = plan

  assert {
    condition     = length(aws_securityhub_standards_subscription.this) == 2
    error_message = "Should subscribe to 2 standards."
  }

  assert {
    condition     = aws_securityhub_standards_subscription.this["aws_foundational"].standards_arn == "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
    error_message = "AWS Foundational standard ARN should be correct."
  }

  assert {
    condition     = aws_securityhub_standards_subscription.this["cis_1_4"].standards_arn == "arn:aws:securityhub:us-east-1::standards/cis-aws-foundations-benchmark/v/1.4.0"
    error_message = "CIS 1.4 standard ARN should be correct."
  }
}

# -----------------------------------------------------------------------------
# Test: Standards can be customized (single standard)
# -----------------------------------------------------------------------------

run "single_standard" {
  command = plan

  variables {
    standards = {
      aws_foundational = {
        arn = "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
      }
    }
    disabled_controls = {}
  }

  assert {
    condition     = length(aws_securityhub_standards_subscription.this) == 1
    error_message = "Should subscribe to only 1 standard."
  }
}

# -----------------------------------------------------------------------------
# Test: Disabled standard not subscribed
# -----------------------------------------------------------------------------

run "disabled_standard_not_subscribed" {
  command = plan

  variables {
    standards = {
      aws_foundational = {
        arn     = "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
        enabled = true
      }
      cis_disabled = {
        arn     = "arn:aws:securityhub:us-east-1::standards/cis-aws-foundations-benchmark/v/1.4.0"
        enabled = false
      }
    }
    disabled_controls = {}
  }

  assert {
    condition     = length(aws_securityhub_standards_subscription.this) == 1
    error_message = "Should only subscribe to enabled standards (1 of 2)."
  }
}

# -----------------------------------------------------------------------------
# Test: Empty standards is valid
# -----------------------------------------------------------------------------

run "empty_standards" {
  command = plan

  variables {
    standards         = {}
    disabled_controls = {}
  }

  assert {
    condition     = length(aws_securityhub_standards_subscription.this) == 0
    error_message = "Should have 0 subscriptions when no standards configured."
  }

  assert {
    condition     = output.security_hub_metadata.standards_count == 0
    error_message = "Metadata should report 0 standards."
  }
}

# -----------------------------------------------------------------------------
# Test: Control override created
# -----------------------------------------------------------------------------

run "control_override_created" {
  command = plan

  assert {
    condition     = length(aws_securityhub_standards_control_association.disabled) == 1
    error_message = "Should create 1 control override."
  }

  assert {
    condition     = aws_securityhub_standards_control_association.disabled["disable_cloudtrail_5"].security_control_id == "CloudTrail.5"
    error_message = "Control override should target CloudTrail.5."
  }

  assert {
    condition     = aws_securityhub_standards_control_association.disabled["disable_cloudtrail_5"].association_status == "DISABLED"
    error_message = "Control override status should be DISABLED."
  }
}

# -----------------------------------------------------------------------------
# Test: No control overrides when empty
# -----------------------------------------------------------------------------

run "no_control_overrides_when_empty" {
  command = plan

  variables {
    disabled_controls = {}
  }

  assert {
    condition     = length(aws_securityhub_standards_control_association.disabled) == 0
    error_message = "Should have 0 control overrides when none configured."
  }
}

# -----------------------------------------------------------------------------
# Test: Metadata output correct
# -----------------------------------------------------------------------------

run "metadata_output" {
  command = plan

  assert {
    condition     = output.security_hub_metadata.enable_default_standards == false
    error_message = "Metadata should report enable_default_standards=false."
  }

  assert {
    condition     = output.security_hub_metadata.auto_enable_controls == true
    error_message = "Metadata should report auto_enable_controls=true."
  }

  assert {
    condition     = output.security_hub_metadata.standards_count == 2
    error_message = "Metadata should report 2 enabled standards."
  }

  assert {
    condition     = output.security_hub_metadata.disabled_controls_count == 1
    error_message = "Metadata should report 1 disabled control."
  }
}

# -----------------------------------------------------------------------------
# Test: Enabled standards output
# -----------------------------------------------------------------------------

run "enabled_standards_output" {
  command = plan

  assert {
    condition     = output.enabled_standards["aws_foundational"] == "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
    error_message = "enabled_standards should contain aws_foundational ARN."
  }
}

# -----------------------------------------------------------------------------
# Test: No organization admin resources
# -----------------------------------------------------------------------------

run "no_organization_resources" {
  command = plan

  # Only account + standards + control resources should exist
  assert {
    condition     = aws_securityhub_account.this.enable_default_standards == false
    error_message = "Only account-level resources should be created."
  }
}

# -----------------------------------------------------------------------------
# Test: enable_default_standards can be true
# -----------------------------------------------------------------------------

run "default_standards_enabled" {
  command = plan

  variables {
    enable_default_standards = true
    standards                = {}
    disabled_controls        = {}
  }

  assert {
    condition     = aws_securityhub_account.this.enable_default_standards == true
    error_message = "enable_default_standards should be settable to true."
  }
}
