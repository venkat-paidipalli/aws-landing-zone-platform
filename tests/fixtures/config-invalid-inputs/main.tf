# -----------------------------------------------------------------------------
# Config Invalid Inputs Test Fixture
#
# Used with -var-file flags to test that specific validation rules reject
# bad input. Default values are valid and pass validation.
#
# Usage:
#   terraform plan -var-file=invalid-role-arn.tfvars
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

module "config" {
  source = "../../../modules/config"

  recorder_name                 = var.recorder_name
  recorder_role_arn             = var.recorder_role_arn
  recording_all_resources       = var.recording_all_resources
  selected_resource_types       = var.selected_resource_types
  include_global_resource_types = var.include_global_resource_types
  delivery_channel_name         = var.delivery_channel_name
  delivery_s3_bucket            = var.delivery_s3_bucket
  delivery_s3_key_prefix        = var.delivery_s3_key_prefix
  delivery_sns_topic_arn        = var.delivery_sns_topic_arn
  snapshot_delivery_frequency   = var.snapshot_delivery_frequency
  managed_rules                 = var.managed_rules
  tags                          = var.tags
}

# Pass-through variables with valid defaults
variable "recorder_name" {
  type    = string
  default = "valid-recorder"
}

variable "recorder_role_arn" {
  type    = string
  default = "arn:aws:iam::555500001111:role/config-role"
}

variable "recording_all_resources" {
  type    = bool
  default = true
}

variable "selected_resource_types" {
  type    = list(string)
  default = []
}

variable "include_global_resource_types" {
  type    = bool
  default = true
}

variable "delivery_channel_name" {
  type    = string
  default = "valid-channel"
}

variable "delivery_s3_bucket" {
  type    = string
  default = "valid-config-bucket"
}

variable "delivery_s3_key_prefix" {
  type    = string
  default = ""
}

variable "delivery_sns_topic_arn" {
  type    = string
  default = ""
}

variable "snapshot_delivery_frequency" {
  type    = string
  default = "TwentyFour_Hours"
}

variable "managed_rules" {
  type = map(object({
    name                        = string
    source_identifier           = string
    description                 = optional(string, "")
    input_parameters            = optional(map(string), {})
    maximum_execution_frequency = optional(string, "")
    tags                        = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
