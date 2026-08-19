# -----------------------------------------------------------------------------
# VPC Interface Test Fixture - fictional development VPC
# No AWS credentials required.
# -----------------------------------------------------------------------------

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
  source = "../../../modules/vpc"

  vpc_cidr_block = "10.10.0.0/16"
  vpc_name       = "lz-development"

  subnets = {
    private-a = { cidr_block = "10.10.1.0/24", availability_zone = "us-east-1a" }
    private-b = { cidr_block = "10.10.2.0/24", availability_zone = "us-east-1b" }
    data-a    = { cidr_block = "10.10.11.0/24", availability_zone = "us-east-1a", tags = { Tier = "data" } }
    data-b    = { cidr_block = "10.10.12.0/24", availability_zone = "us-east-1b", tags = { Tier = "data" } }
  }

  tags = { Environment = "development", Project = "landing-zone" }
}

output "vpc_id" { value = module.vpc.vpc_id }
output "subnet_ids" { value = module.vpc.subnet_ids }
output "metadata" { value = module.vpc.vpc_metadata }
