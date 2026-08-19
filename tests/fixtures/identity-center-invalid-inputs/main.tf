# Identity Center Invalid Inputs - defaults valid, use -var-file for failures.
terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0, < 7.0" }
  }
}

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  access_key                  = "mock-access-key-for-validation"
  secret_key                  = "mock-secret-key-for-validation"
}

module "identity_center" {
  source = "../../../modules/identity-center"

  instance_arn    = var.instance_arn
  permission_sets = var.permission_sets
  assignments     = var.assignments
  tags            = var.tags
}

variable "instance_arn" {
  type    = string
  default = "arn:aws:sso:::instance/ssoins-0000000000000001"
}

variable "permission_sets" {
  type = map(object({
    name                      = string
    description               = optional(string, "")
    session_duration          = optional(string, "PT1H")
    relay_state               = optional(string, "")
    aws_managed_policies      = optional(list(string), [])
    customer_managed_policies = optional(list(object({ name = string, path = optional(string, "/") })), [])
    inline_policy             = optional(string, "")
    tags                      = optional(map(string), {})
  }))
  default = {
    test = {
      name        = "Test"
      description = "Valid test permission set"
    }
  }
}

variable "assignments" {
  type = map(object({
    permission_set_key = string
    principal_id       = string
    principal_type     = string
    target_account_id  = string
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
