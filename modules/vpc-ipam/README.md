# VPC IPAM Module

## Status

**Implemented** — creates centralized IP address management with configurable
pools and CIDR provisioning.

## Purpose

Provides centralized CIDR planning for the landing zone:

- IPAM instance with operating regions
- Child pools for environment/workload segmentation
- Provisioned CIDRs for VPC allocation
- Prevents address overlap across the organization

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_vpc_ipam.this` | IPAM instance |
| `aws_vpc_ipam_pool.this` | Child pools (for_each) |
| `aws_vpc_ipam_pool_cidr.this` | Provisioned CIDRs (flattened) |

## Pool Hierarchy

```
IPAM (private default scope)
├── nonprod pool (10.1.0.0/16, 10.2.0.0/16)
├── prod pool (10.3.0.0/16)
├── shared-services pool (10.4.0.0/16)
└── sandbox pool (10.5.0.0/16)
```

v1 supports one level of child pools under the IPAM's private scope.
Nested sub-pools can be added in future iterations.

## What This Module Does NOT Create

- VPCs (use the vpc module)
- CIDR allocations from pools to VPCs (environment layer)
- Cross-account pool sharing via RAM (future)
- IPv6 pools (IPv4 only in v1)
- Nested sub-pools (one level in v1)

## Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `operating_regions` | `list(string)` | Yes | — | IPAM regions (min 1) |
| `description` | `string` | No | `"Landing zone..."` | IPAM description |
| `pools` | `map(object)` | No | `{}` | Pool definitions |
| `tags` | `map(string)` | No | `{}` | Tags |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `ipam_id` | `string` | IPAM ID |
| `ipam_arn` | `string` | IPAM ARN |
| `private_scope_id` | `string` | Private scope ID |
| `pool_ids` | `map(string)` | Pool key → ID |
| `pool_arns` | `map(string)` | Pool key → ARN |
| `pool_cidrs` | `map(string)` | "pool:cidr" → CIDR |
| `ipam_metadata` | `object` | Summary |

## Example Usage

```hcl
module "ipam" {
  source = "../../modules/vpc-ipam"

  operating_regions = ["us-east-1", "us-west-2"]

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

  tags = { Project = "landing-zone" }
}
```
