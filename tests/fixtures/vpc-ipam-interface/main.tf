# -----------------------------------------------------------------------------
# VPC IPAM Interface Test Fixture - fictional CIDR plan
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

module "ipam" {
  source = "../../../modules/vpc-ipam"

  operating_regions = ["us-east-1"]

  pools = {
    nonprod = {
      description = "Non-production"
      locale      = "us-east-1"
      cidrs       = ["10.1.0.0/16", "10.2.0.0/16"]
    }
    prod = {
      description = "Production"
      locale      = "us-east-1"
      cidrs       = ["10.3.0.0/16"]
    }
  }

  tags = { Project = "landing-zone" }
}

output "ipam_id" { value = module.ipam.ipam_id }
output "pool_ids" { value = module.ipam.pool_ids }
output "metadata" { value = module.ipam.ipam_metadata }
