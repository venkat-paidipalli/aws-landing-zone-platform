# -----------------------------------------------------------------------------
# GuardDuty Interface Test Fixture
#
# Demonstrates a realistic standalone GuardDuty detector configuration.
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
# GuardDuty Module - Production configuration
# -----------------------------------------------------------------------------

module "guardduty" {
  source = "../../../modules/guardduty"

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  enable_s3_protection         = true
  enable_kubernetes_protection = false
  enable_malware_protection    = false

  tags = {
    Environment = "production"
    Project     = "landing-zone"
    Owner       = "security-team"
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "detector_id" {
  value = module.guardduty.detector_id
}

output "detector_enabled" {
  value = module.guardduty.detector_enabled
}

output "enabled_features" {
  value = module.guardduty.enabled_features
}

output "metadata" {
  value = module.guardduty.guardduty_metadata
}
