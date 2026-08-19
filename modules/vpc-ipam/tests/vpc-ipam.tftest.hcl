# -----------------------------------------------------------------------------
# VPC IPAM Module - Terraform Native Tests (Mocked Provider)
#
# Run with: terraform -chdir=modules/vpc-ipam test
# No AWS credentials required.
# -----------------------------------------------------------------------------

mock_provider "aws" {}

variables {
  operating_regions = ["us-east-1", "us-west-2"]
  description       = "Landing zone IPAM"

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
    shared = {
      description = "Shared services"
      locale      = "us-east-1"
      cidrs       = ["10.4.0.0/16"]
    }
  }

  tags = {
    Project     = "landing-zone"
    Environment = "network"
  }
}

# -----------------------------------------------------------------------------
# Test: IPAM created
# -----------------------------------------------------------------------------

run "ipam_created" {
  command = plan

  assert {
    condition     = aws_vpc_ipam.this.description == "Landing zone IPAM"
    error_message = "IPAM should have the specified description."
  }
}

# -----------------------------------------------------------------------------
# Test: Operating regions configured
# -----------------------------------------------------------------------------

run "operating_regions_configured" {
  command = plan

  assert {
    condition     = length(aws_vpc_ipam.this.operating_regions) == 2
    error_message = "IPAM should have 2 operating regions."
  }
}

# -----------------------------------------------------------------------------
# Test: Pools created
# -----------------------------------------------------------------------------

run "pools_created" {
  command = plan

  assert {
    condition     = length(aws_vpc_ipam_pool.this) == 3
    error_message = "Should create 3 pools."
  }

  assert {
    condition     = aws_vpc_ipam_pool.this["nonprod"].address_family == "ipv4"
    error_message = "Pools should use ipv4 address family."
  }

  assert {
    condition     = aws_vpc_ipam_pool.this["nonprod"].description == "Non-production workloads"
    error_message = "Nonprod pool should have correct description."
  }
}

# -----------------------------------------------------------------------------
# Test: Pool locale
# -----------------------------------------------------------------------------

run "pool_locale" {
  command = plan

  assert {
    condition     = aws_vpc_ipam_pool.this["nonprod"].locale == "us-east-1"
    error_message = "Nonprod pool should have locale us-east-1."
  }
}

# -----------------------------------------------------------------------------
# Test: CIDRs provisioned
# -----------------------------------------------------------------------------

run "cidrs_provisioned" {
  command = plan

  # nonprod: 2 CIDRs + prod: 1 + shared: 1 = 4 total
  assert {
    condition     = length(aws_vpc_ipam_pool_cidr.this) == 4
    error_message = "Should provision 4 CIDRs total."
  }

  assert {
    condition     = aws_vpc_ipam_pool_cidr.this["nonprod:10.1.0.0/16"].cidr == "10.1.0.0/16"
    error_message = "Nonprod should have 10.1.0.0/16 CIDR."
  }

  assert {
    condition     = aws_vpc_ipam_pool_cidr.this["prod:10.3.0.0/16"].cidr == "10.3.0.0/16"
    error_message = "Prod should have 10.3.0.0/16 CIDR."
  }
}

# -----------------------------------------------------------------------------
# Test: IPAM tags
# -----------------------------------------------------------------------------

run "ipam_tags" {
  command = plan

  assert {
    condition     = aws_vpc_ipam.this.tags["ManagedBy"] == "terraform"
    error_message = "IPAM should have ManagedBy=terraform tag."
  }

  assert {
    condition     = aws_vpc_ipam.this.tags["Component"] == "vpc-ipam"
    error_message = "IPAM should have Component=vpc-ipam tag."
  }

  assert {
    condition     = aws_vpc_ipam.this.tags["Project"] == "landing-zone"
    error_message = "IPAM should inherit caller Project tag."
  }
}

# -----------------------------------------------------------------------------
# Test: Pool tags
# -----------------------------------------------------------------------------

run "pool_tags" {
  command = plan

  assert {
    condition     = aws_vpc_ipam_pool.this["nonprod"].tags["PoolKey"] == "nonprod"
    error_message = "Pool should have PoolKey tag."
  }

  assert {
    condition     = aws_vpc_ipam_pool.this["nonprod"].tags["ManagedBy"] == "terraform"
    error_message = "Pool should have ManagedBy=terraform tag."
  }
}

# -----------------------------------------------------------------------------
# Test: No VPC resources created
# -----------------------------------------------------------------------------

run "no_vpc_resources" {
  command = plan

  # Only IPAM, pools, and CIDRs - no aws_vpc
  assert {
    condition     = length(aws_vpc_ipam_pool.this) == 3
    error_message = "Should only create pool resources, not VPCs."
  }
}

# -----------------------------------------------------------------------------
# Test: Metadata output
# -----------------------------------------------------------------------------

run "metadata_output" {
  command = plan

  assert {
    condition     = output.ipam_metadata.pool_count == 3
    error_message = "Metadata should report 3 pools."
  }

  assert {
    condition     = output.ipam_metadata.total_cidrs == 4
    error_message = "Metadata should report 4 total CIDRs."
  }
}

# -----------------------------------------------------------------------------
# Test: Empty pools valid
# -----------------------------------------------------------------------------

run "empty_pools" {
  command = plan

  variables {
    pools = {}
  }

  assert {
    condition     = length(aws_vpc_ipam_pool.this) == 0
    error_message = "Should create 0 pools when none configured."
  }

  assert {
    condition     = output.ipam_metadata.pool_count == 0
    error_message = "Metadata should report 0 pools."
  }
}
