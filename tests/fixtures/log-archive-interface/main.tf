# -----------------------------------------------------------------------------
# Log Archive Interface Test Fixture
#
# Demonstrates standalone log archive configuration. All values fictional.
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
  }
}

output "bucket_name" {
  value = module.log_archive.bucket_name
}

output "metadata" {
  value = module.log_archive.log_archive_metadata
}
