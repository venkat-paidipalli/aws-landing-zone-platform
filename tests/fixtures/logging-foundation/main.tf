# -----------------------------------------------------------------------------
# Logging Foundation Integration Fixture
#
# Composes log-archive and cloudtrail modules to demonstrate how independently
# designed modules wire together. The log-archive bucket output feeds into
# the cloudtrail module's s3_bucket_name input.
#
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

# -----------------------------------------------------------------------------
# Log Archive - Secure S3 storage
# -----------------------------------------------------------------------------

module "log_archive" {
  source = "../../../modules/log-archive"

  bucket_name     = "lz-audit-logs-555500001111"
  encryption_type = "AES256"

  transition_to_ia_days      = 90
  transition_to_glacier_days = 365
  expiration_days            = 2555

  tags = {
    Environment = "production"
    Project     = "landing-zone"
    Component   = "logging"
  }
}

# -----------------------------------------------------------------------------
# CloudTrail - Audit event collection, wired to log-archive output
# -----------------------------------------------------------------------------

module "cloudtrail" {
  source = "../../../modules/cloudtrail"

  trail_name     = "lz-account-trail"
  s3_bucket_name = module.log_archive.bucket_name
  s3_key_prefix  = "cloudtrail"

  tags = {
    Environment = "production"
    Project     = "landing-zone"
    Component   = "logging"
  }
}

# -----------------------------------------------------------------------------
# Outputs - demonstrate integration wiring
# -----------------------------------------------------------------------------

output "log_archive_bucket" {
  value = module.log_archive.bucket_name
}

output "cloudtrail_name" {
  value = module.cloudtrail.trail_name
}

output "cloudtrail_delivers_to" {
  value = module.cloudtrail.cloudtrail_metadata.s3_bucket
}
