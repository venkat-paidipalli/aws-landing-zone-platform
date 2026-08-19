# -----------------------------------------------------------------------------
# VPC Module - Terraform Native Tests (Mocked Provider)
#
# Run with: terraform -chdir=modules/vpc test
# No AWS credentials required.
# -----------------------------------------------------------------------------

mock_provider "aws" {}

variables {
  vpc_cidr_block       = "10.10.0.0/16"
  vpc_name             = "lz-development"
  enable_dns_support   = true
  enable_dns_hostnames = true

  subnets = {
    private-a = {
      cidr_block        = "10.10.1.0/24"
      availability_zone = "us-east-1a"
    }
    private-b = {
      cidr_block        = "10.10.2.0/24"
      availability_zone = "us-east-1b"
    }
    data-a = {
      cidr_block        = "10.10.11.0/24"
      availability_zone = "us-east-1a"
      tags              = { Tier = "data" }
    }
    data-b = {
      cidr_block        = "10.10.12.0/24"
      availability_zone = "us-east-1b"
      tags              = { Tier = "data" }
    }
  }

  create_internet_gateway = false
  enable_flow_logs        = false

  tags = {
    Environment = "development"
    Project     = "landing-zone"
  }
}

# -----------------------------------------------------------------------------
# Test: VPC created with correct CIDR
# -----------------------------------------------------------------------------

run "vpc_created" {
  command = plan

  assert {
    condition     = aws_vpc.this.cidr_block == "10.10.0.0/16"
    error_message = "VPC should have the specified CIDR block."
  }
}

# -----------------------------------------------------------------------------
# Test: DNS support enabled
# -----------------------------------------------------------------------------

run "dns_support_enabled" {
  command = plan

  assert {
    condition     = aws_vpc.this.enable_dns_support == true
    error_message = "DNS support should be enabled."
  }
}

# -----------------------------------------------------------------------------
# Test: DNS hostnames enabled
# -----------------------------------------------------------------------------

run "dns_hostnames_enabled" {
  command = plan

  assert {
    condition     = aws_vpc.this.enable_dns_hostnames == true
    error_message = "DNS hostnames should be enabled."
  }
}

# -----------------------------------------------------------------------------
# Test: Subnets created
# -----------------------------------------------------------------------------

run "subnets_created" {
  command = plan

  assert {
    condition     = length(aws_subnet.this) == 4
    error_message = "Should create 4 subnets."
  }

  assert {
    condition     = aws_subnet.this["private-a"].cidr_block == "10.10.1.0/24"
    error_message = "private-a subnet should have correct CIDR."
  }

  assert {
    condition     = aws_subnet.this["private-a"].availability_zone == "us-east-1a"
    error_message = "private-a subnet should be in us-east-1a."
  }
}

# -----------------------------------------------------------------------------
# Test: Subnet tags include tier
# -----------------------------------------------------------------------------

run "subnet_tags" {
  command = plan

  assert {
    condition     = aws_subnet.this["private-a"].tags["Tier"] == "private"
    error_message = "Private subnets should have Tier=private tag."
  }

  assert {
    condition     = aws_subnet.this["private-a"].tags["ManagedBy"] == "terraform"
    error_message = "Subnets should have ManagedBy=terraform tag."
  }

  assert {
    condition     = aws_subnet.this["private-a"].tags["SubnetKey"] == "private-a"
    error_message = "Subnets should have SubnetKey tag."
  }
}

# -----------------------------------------------------------------------------
# Test: Public/private classification
# -----------------------------------------------------------------------------

run "subnet_classification" {
  command = plan

  assert {
    condition     = aws_subnet.this["private-a"].map_public_ip_on_launch == false
    error_message = "Private subnets should not map public IPs."
  }
}

# -----------------------------------------------------------------------------
# Test: Route tables created (private only, no public subnets)
# -----------------------------------------------------------------------------

run "route_tables_private_only" {
  command = plan

  assert {
    condition     = length(aws_route_table.private) == 1
    error_message = "Should create 1 private route table."
  }

  assert {
    condition     = length(aws_route_table.public) == 0
    error_message = "Should not create public route table when no public subnets."
  }
}

# -----------------------------------------------------------------------------
# Test: No IGW by default
# -----------------------------------------------------------------------------

run "no_igw_by_default" {
  command = plan

  assert {
    condition     = length(aws_internet_gateway.this) == 0
    error_message = "No IGW should be created by default."
  }

  assert {
    condition     = output.internet_gateway_id == null
    error_message = "internet_gateway_id output should be null."
  }
}

# -----------------------------------------------------------------------------
# Test: Optional IGW
# -----------------------------------------------------------------------------

run "optional_igw" {
  command = plan

  variables {
    create_internet_gateway = true
    subnets = {
      public-a = {
        cidr_block        = "10.10.100.0/24"
        availability_zone = "us-east-1a"
        public            = true
      }
      private-a = {
        cidr_block        = "10.10.1.0/24"
        availability_zone = "us-east-1a"
      }
    }
  }

  assert {
    condition     = length(aws_internet_gateway.this) == 1
    error_message = "IGW should be created when enabled."
  }

  assert {
    condition     = length(aws_route_table.public) == 1
    error_message = "Public route table should be created for public subnets."
  }
}

# -----------------------------------------------------------------------------
# Test: Flow logs disabled by default
# -----------------------------------------------------------------------------

run "flow_logs_disabled" {
  command = plan

  assert {
    condition     = length(aws_flow_log.this) == 0
    error_message = "Flow logs should not be created by default."
  }
}

# -----------------------------------------------------------------------------
# Test: Flow logs enabled
# -----------------------------------------------------------------------------

run "flow_logs_enabled" {
  command = plan

  variables {
    enable_flow_logs           = true
    flow_logs_destination      = "arn:aws:s3:::lz-flow-logs-555500001111"
    flow_logs_destination_type = "s3"
  }

  assert {
    condition     = length(aws_flow_log.this) == 1
    error_message = "Flow logs should be created when enabled."
  }

  assert {
    condition     = aws_flow_log.this[0].traffic_type == "ALL"
    error_message = "Flow logs should capture ALL traffic by default."
  }
}

# -----------------------------------------------------------------------------
# Test: VPC tags
# -----------------------------------------------------------------------------

run "vpc_tags" {
  command = plan

  assert {
    condition     = aws_vpc.this.tags["ManagedBy"] == "terraform"
    error_message = "VPC should have ManagedBy=terraform tag."
  }

  assert {
    condition     = aws_vpc.this.tags["Component"] == "vpc"
    error_message = "VPC should have Component=vpc tag."
  }

  assert {
    condition     = aws_vpc.this.tags["Environment"] == "development"
    error_message = "VPC should inherit Environment tag."
  }
}

# -----------------------------------------------------------------------------
# Test: Metadata output
# -----------------------------------------------------------------------------

run "metadata_output" {
  command = plan

  assert {
    condition     = output.vpc_metadata.vpc_cidr == "10.10.0.0/16"
    error_message = "Metadata should report VPC CIDR."
  }

  assert {
    condition     = output.vpc_metadata.subnet_count == 4
    error_message = "Metadata should report 4 subnets."
  }

  assert {
    condition     = output.vpc_metadata.private_subnet_count == 4
    error_message = "Metadata should report 4 private subnets."
  }

  assert {
    condition     = output.vpc_metadata.public_subnet_count == 0
    error_message = "Metadata should report 0 public subnets."
  }

  assert {
    condition     = output.vpc_metadata.internet_gateway == false
    error_message = "Metadata should report no IGW."
  }

  assert {
    condition     = output.vpc_metadata.flow_logs_enabled == false
    error_message = "Metadata should report flow logs disabled."
  }
}

# -----------------------------------------------------------------------------
# Test: Default security group restricted
# -----------------------------------------------------------------------------

run "default_sg_restricted" {
  command = plan

  assert {
    condition     = aws_default_security_group.this.tags["Name"] == "default-restricted"
    error_message = "Default security group should be managed and named default-restricted."
  }
}
