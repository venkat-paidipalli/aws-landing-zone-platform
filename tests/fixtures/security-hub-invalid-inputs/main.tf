# -----------------------------------------------------------------------------
# Security Hub Invalid Inputs Test Fixture
#
# Used with -var-file flags to test that specific validation rules reject
# bad input. Default values are valid and pass validation.
#
# Usage:
#   terraform plan -var-file=invalid-standards-arn.tfvars
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

module "security_hub" {
  source = "../../../modules/security-hub"

  enable_default_standards = var.enable_default_standards
  auto_enable_controls     = var.auto_enable_controls
  standards                = var.standards
  disabled_controls        = var.disabled_controls
  tags                     = var.tags
}

variable "enable_default_standards" {
  type    = bool
  default = false
}

variable "auto_enable_controls" {
  type    = bool
  default = true
}

variable "standards" {
  type = map(object({
    arn     = string
    enabled = optional(bool, true)
  }))
  default = {}
}

variable "disabled_controls" {
  type = map(object({
    standards_arn = string
    control_id    = string
    reason        = optional(string, "Disabled by platform configuration")
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
