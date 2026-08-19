# -----------------------------------------------------------------------------
# CloudTrail Invalid Inputs Test Fixture
# Default values are valid. Use -var-file for invalid cases.
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

  trail_name                       = var.trail_name
  s3_bucket_name                   = var.s3_bucket_name
  management_event_read_write_type = var.management_event_read_write_type
  tags                             = var.tags
}

variable "trail_name" {
  type    = string
  default = "valid-trail-name"
}

variable "s3_bucket_name" {
  type    = string
  default = "valid-bucket-name"
}

variable "management_event_read_write_type" {
  type    = string
  default = "All"
}

variable "tags" {
  type    = map(string)
  default = {}
}
