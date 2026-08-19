# -----------------------------------------------------------------------------
# GuardDuty Invalid Inputs Test Fixture
#
# Used with -var-file flags to test that specific validation rules reject
# bad input. Default values are valid and pass validation.
#
# Usage:
#   terraform plan -var-file=invalid-frequency.tfvars
#
# Expected: FAIL for each -var-file. Not part of CI validation.
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

module "guardduty" {
  source = "../../../modules/guardduty"

  enable                       = var.enable
  finding_publishing_frequency = var.finding_publishing_frequency
  enable_s3_protection         = var.enable_s3_protection
  enable_kubernetes_protection = var.enable_kubernetes_protection
  enable_malware_protection    = var.enable_malware_protection
  tags                         = var.tags
}

variable "enable" {
  type    = bool
  default = true
}

variable "finding_publishing_frequency" {
  type    = string
  default = "FIFTEEN_MINUTES"
}

variable "enable_s3_protection" {
  type    = bool
  default = true
}

variable "enable_kubernetes_protection" {
  type    = bool
  default = false
}

variable "enable_malware_protection" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
