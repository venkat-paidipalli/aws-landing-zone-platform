# -----------------------------------------------------------------------------
# CloudTrail Interface Test Fixture
#
# Demonstrates standalone CloudTrail configuration. All values fictional.
# No AWS credentials required.
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

module "cloudtrail" {
  source = "../../../modules/cloudtrail"

  trail_name     = "lz-account-trail"
  s3_bucket_name = "lz-audit-logs-555500001111"
  s3_key_prefix  = "cloudtrail"

  tags = {
    Environment = "production"
    Project     = "landing-zone"
  }
}

output "trail_name" {
  value = module.cloudtrail.trail_name
}

output "metadata" {
  value = module.cloudtrail.cloudtrail_metadata
}
