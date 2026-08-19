# -----------------------------------------------------------------------------
# Organization Invalid Inputs Test Fixture
#
# This configuration is used with -var-file flags to test that specific
# validation rules reject bad input. Each .tfvars file overrides one variable
# with invalid data to trigger a specific validation error.
#
# Usage:
#   terraform plan -var-file=invalid-feature-set.tfvars
#
# These are expected to FAIL. They are not part of CI validation.
# The default values (without -var-file) are valid and pass validation.
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

  # No real credentials — this fixture is for validation testing only.
  access_key = "mock-access-key-for-validation"
  secret_key = "mock-secret-key-for-validation"
}

module "organization" {
  source = "../../../modules/organization"

  organization_name    = var.organization_name
  feature_set          = var.feature_set
  organizational_units = var.organizational_units
  accounts             = var.accounts
}

# Pass-through variables to allow override via -var-file
variable "organization_name" {
  type    = string
  default = "valid-org-name"
}

variable "feature_set" {
  type    = string
  default = "ALL"
}

variable "organizational_units" {
  type = map(object({
    name        = optional(string)
    parent      = string
    description = optional(string, "")
    tags        = optional(map(string), {})
  }))
  default = {
    Security = {
      parent      = "ROOT"
      description = "Security OU"
    }
  }
}

variable "accounts" {
  type = map(object({
    name      = string
    email     = string
    ou_path   = string
    role_name = optional(string, "OrganizationAccountAccessRole")
    tags      = optional(map(string), {})
  }))
  default = {
    test = {
      name    = "lz-test"
      email   = "aws+test@example.invalid"
      ou_path = "Security"
    }
  }
}
