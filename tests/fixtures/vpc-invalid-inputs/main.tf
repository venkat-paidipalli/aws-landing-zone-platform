# VPC Invalid Inputs - defaults are valid, use -var-file for invalid cases.
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

module "vpc" {
  source         = "../../../modules/vpc"
  vpc_cidr_block = var.vpc_cidr_block
  subnets        = var.subnets
  tags           = var.tags
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnets" {
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    public                  = optional(bool, false)
    map_public_ip_on_launch = optional(bool, false)
    tags                    = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
