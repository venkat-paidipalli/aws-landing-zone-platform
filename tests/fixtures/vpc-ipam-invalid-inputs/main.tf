# VPC IPAM Invalid Inputs - defaults valid, use -var-file for failures.
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

module "ipam" {
  source            = "../../../modules/vpc-ipam"
  operating_regions = var.operating_regions
  pools             = var.pools
  tags              = var.tags
}

variable "operating_regions" {
  type    = list(string)
  default = ["us-east-1"]
}

variable "pools" {
  type = map(object({
    description = optional(string, "")
    locale      = optional(string, "")
    cidrs       = list(string)
    tags        = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
