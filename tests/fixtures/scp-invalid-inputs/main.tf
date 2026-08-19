# -----------------------------------------------------------------------------
# SCP Invalid Inputs Test Fixture
#
# Used with -var-file flags to test that specific validation rules reject bad
# input. The default values are valid and pass validation.
#
# Usage:
#   terraform plan -var-file=invalid-empty-name.tfvars
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

module "scp" {
  source = "../../../modules/scp"

  approved_regions = var.approved_regions
  target_ids       = var.target_ids
  policies         = var.policies
}

variable "approved_regions" {
  type    = list(string)
  default = ["us-east-1"]
}

variable "target_ids" {
  type = map(string)
  default = {
    "Security" = "ou-synth-security"
  }
}

variable "policies" {
  type = map(object({
    name        = string
    description = string
    content     = string
    targets     = list(string)
    tags        = optional(map(string), {})
  }))
  default = {
    test_policy = {
      name        = "test-policy"
      description = "A valid test policy"
      content     = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Deny\",\"Action\":\"*\",\"Resource\":\"*\"}]}"
      targets     = ["Security"]
    }
  }
}
