# -----------------------------------------------------------------------------
# Security Hub Interface Test Fixture
#
# Demonstrates a realistic standalone Security Hub account-level configuration.
# No real AWS accounts, credentials, or organization IDs.
#
# No AWS credentials required (uses provider with skip flags).
# -----------------------------------------------------------------------------

terraform {
  required_version = "~> 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  access_key = "mock-access-key-for-validation"
  secret_key = "mock-secret-key-for-validation"
}

# -----------------------------------------------------------------------------
# Security Hub Module - Production configuration
# -----------------------------------------------------------------------------

module "security_hub" {
  source = "../../../modules/security-hub"

  enable_default_standards = false
  auto_enable_controls     = true

  standards = {
    aws_foundational = {
      arn = "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
    }
    cis_1_4 = {
      arn     = "arn:aws:securityhub:us-east-1::standards/cis-aws-foundations-benchmark/v/1.4.0"
      enabled = false # Enable after foundational baseline is clean
    }
  }

  disabled_controls = {
    disable_cloudtrail_multi_region = {
      standards_arn = "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
      control_id    = "CloudTrail.5"
      reason        = "Multi-region trail managed by organization-level CloudTrail module"
    }
  }

  tags = {
    Environment = "production"
    Project     = "landing-zone"
    Owner       = "security-team"
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "security_hub_enabled" {
  value = module.security_hub.security_hub_enabled
}

output "enabled_standards" {
  value = module.security_hub.enabled_standards
}

output "metadata" {
  value = module.security_hub.security_hub_metadata
}
