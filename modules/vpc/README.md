# VPC Module

## Status

**Implemented** — creates a configurable VPC with subnets, route tables, and
optional Internet Gateway and Flow Logs.

## Purpose

Provides a reusable VPC baseline for landing-zone accounts:

- Configurable CIDR and subnet layout
- Public/private subnet classification
- Dedicated route tables per tier
- Optional Internet Gateway (disabled by default)
- Optional VPC Flow Logs (external destination)
- No NAT Gateway (future enhancement, cost implications)

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_vpc.this` | The VPC |
| `aws_subnet.this` | Subnets (for_each) |
| `aws_route_table.public` | Public route table (if public subnets exist) |
| `aws_route_table.private` | Private route table (if private subnets exist) |
| `aws_route_table_association.public` | Public subnet associations |
| `aws_route_table_association.private` | Private subnet associations |
| `aws_internet_gateway.this` | IGW (optional) |
| `aws_route.public_internet` | Default route via IGW (if IGW + public subnets) |
| `aws_flow_log.this` | Flow Logs (optional) |

## Conservative Defaults

| Setting | Default | Rationale |
|---------|---------|-----------|
| `create_internet_gateway` | `false` | Not every VPC needs internet access |
| `enable_flow_logs` | `false` | Destination must be provided externally |
| `map_public_ip_on_launch` | `false` | No auto-public IPs |
| `enable_dns_support` | `true` | Required for Route 53 Resolver |
| `enable_dns_hostnames` | `true` | Required for private DNS |

## Subnet Model

```hcl
subnets = {
  private-a = {
    cidr_block        = "10.10.1.0/24"
    availability_zone = "us-east-1a"
  }
  public-a = {
    cidr_block              = "10.10.100.0/24"
    availability_zone       = "us-east-1a"
    public                  = true
    map_public_ip_on_launch = true
  }
}
```

## What This Module Does NOT Create

- NAT Gateways (cost, complexity — future enhancement)
- Transit Gateway attachments (separate TGW module)
- Network Firewall (separate module)
- VPN/Direct Connect
- Custom NACLs (relies on default + security groups + routing)
- Route 53 Resolver endpoints

## Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `vpc_cidr_block` | `string` | Yes | — | VPC CIDR |
| `vpc_name` | `string` | No | `""` | Name tag |
| `enable_dns_support` | `bool` | No | `true` | DNS support |
| `enable_dns_hostnames` | `bool` | No | `true` | DNS hostnames |
| `instance_tenancy` | `string` | No | `"default"` | Tenancy |
| `subnets` | `map(object)` | No | `{}` | Subnet definitions |
| `create_internet_gateway` | `bool` | No | `false` | Create IGW |
| `enable_flow_logs` | `bool` | No | `false` | Enable flow logs |
| `flow_logs_destination` | `string` | No | `""` | Flow log dest ARN |
| `flow_logs_destination_type` | `string` | No | `"cloud-watch-logs"` | Dest type |
| `flow_logs_iam_role_arn` | `string` | No | `""` | IAM role for CW |
| `flow_logs_traffic_type` | `string` | No | `"ALL"` | Traffic filter |
| `tags` | `map(string)` | No | `{}` | Tags |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `vpc_id` | `string` | VPC ID |
| `vpc_arn` | `string` | VPC ARN |
| `vpc_cidr_block` | `string` | VPC CIDR |
| `subnet_ids` | `map(string)` | Subnet key → ID |
| `subnet_cidr_blocks` | `map(string)` | Subnet key → CIDR |
| `subnet_arns` | `map(string)` | Subnet key → ARN |
| `route_table_ids` | `map(string)` | Type → route table ID |
| `internet_gateway_id` | `string` | IGW ID or null |
| `vpc_metadata` | `object` | Summary |

## Example Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr_block = "10.1.0.0/16"
  vpc_name       = "lz-development"

  subnets = {
    private-a = {
      cidr_block        = "10.1.1.0/24"
      availability_zone = "us-east-1a"
    }
    private-b = {
      cidr_block        = "10.1.2.0/24"
      availability_zone = "us-east-1b"
    }
    data-a = {
      cidr_block        = "10.1.11.0/24"
      availability_zone = "us-east-1a"
      tags              = { Tier = "data" }
    }
  }

  tags = {
    Environment = "development"
    Project     = "landing-zone"
  }
}
```
