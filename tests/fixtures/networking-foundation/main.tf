# -----------------------------------------------------------------------------
# Networking Foundation Integration Fixture
#
# Demonstrates IPAM + VPC module composition. In production, VPCs would
# allocate CIDRs from IPAM pools. In v1 with static CIDRs, this fixture
# shows the intended relationship through co-located configuration.
#
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

# -----------------------------------------------------------------------------
# IPAM - Central address management
# -----------------------------------------------------------------------------

module "ipam" {
  source = "../../../modules/vpc-ipam"

  operating_regions = ["us-east-1"]

  pools = {
    nonprod = {
      description = "Non-production workloads"
      locale      = "us-east-1"
      cidrs       = ["10.1.0.0/16", "10.2.0.0/16"]
    }
    prod = {
      description = "Production workloads"
      locale      = "us-east-1"
      cidrs       = ["10.3.0.0/16"]
    }
  }

  tags = { Project = "landing-zone" }
}

# -----------------------------------------------------------------------------
# VPC - Development workload (uses CIDR from nonprod pool range)
# In production, this CIDR would be allocated from IPAM pool dynamically.
# For v1, static CIDRs demonstrate the planned addressing model.
# -----------------------------------------------------------------------------

module "vpc_development" {
  source = "../../../modules/vpc"

  vpc_cidr_block = "10.1.0.0/16"
  vpc_name       = "lz-development"

  subnets = {
    private-a = { cidr_block = "10.1.1.0/24", availability_zone = "us-east-1a" }
    private-b = { cidr_block = "10.1.2.0/24", availability_zone = "us-east-1b" }
    data-a    = { cidr_block = "10.1.11.0/24", availability_zone = "us-east-1a" }
    data-b    = { cidr_block = "10.1.12.0/24", availability_zone = "us-east-1b" }
  }

  tags = { Environment = "development", Project = "landing-zone" }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "ipam_id" { value = module.ipam.ipam_id }
output "ipam_pools" { value = module.ipam.pool_ids }
output "vpc_id" { value = module.vpc_development.vpc_id }
output "vpc_cidr" { value = module.vpc_development.vpc_cidr_block }
output "subnet_ids" { value = module.vpc_development.subnet_ids }
