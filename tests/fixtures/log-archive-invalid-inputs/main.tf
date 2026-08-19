# -----------------------------------------------------------------------------
# Log Archive Invalid Inputs Test Fixture
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

module "log_archive" {
  source = "../../../modules/log-archive"

  bucket_name     = var.bucket_name
  encryption_type = var.encryption_type
  kms_key_arn     = var.kms_key_arn
  tags            = var.tags
}

variable "bucket_name" {
  type    = string
  default = "valid-log-bucket-name"
}

variable "encryption_type" {
  type    = string
  default = "AES256"
}

variable "kms_key_arn" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
