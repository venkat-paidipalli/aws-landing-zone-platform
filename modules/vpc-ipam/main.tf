# -----------------------------------------------------------------------------
# VPC IPAM Module - Main
#
# Creates centralized IP address management infrastructure:
# - IPAM instance with operating regions
# - Child pools with provisioned CIDRs
#
# This provides the addressing foundation. VPCs can later allocate CIDRs
# from these pools (via aws_vpc_ipam_pool_cidr_allocation or VPC ipv4_ipam_pool_id).
#
# NOT in scope:
# - VPC creation (use vpc module)
# - CIDR allocation to VPCs (environment layer responsibility)
# - Transit Gateway routing
# - Cross-account pool sharing (future RAM integration)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# IPAM Instance
# -----------------------------------------------------------------------------

resource "aws_vpc_ipam" "this" {
  description = var.description

  dynamic "operating_regions" {
    for_each = var.operating_regions
    content {
      region_name = operating_regions.value
    }
  }

  tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Component = "vpc-ipam"
    },
  )
}

# -----------------------------------------------------------------------------
# IPAM Pools
#
# Each pool is a child of the IPAM's default private scope.
# Pools can have a locale (region) for regional allocation.
# -----------------------------------------------------------------------------

resource "aws_vpc_ipam_pool" "this" {
  for_each = var.pools

  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam.this.private_default_scope_id
  locale         = each.value.locale != "" ? each.value.locale : null
  description    = each.value.description

  tags = merge(
    var.tags,
    each.value.tags,
    {
      ManagedBy = "terraform"
      Component = "vpc-ipam"
      PoolKey   = each.key
    },
  )
}

# -----------------------------------------------------------------------------
# Pool CIDRs
#
# Provisions CIDR ranges into each pool. VPCs can then allocate from these.
# Uses a flattened map with deterministic keys: "pool_key:cidr"
# -----------------------------------------------------------------------------

locals {
  pool_cidrs = merge([
    for pool_key, pool in var.pools : {
      for cidr in pool.cidrs :
      "${pool_key}:${cidr}" => {
        pool_key = pool_key
        cidr     = cidr
      }
    }
  ]...)
}

resource "aws_vpc_ipam_pool_cidr" "this" {
  for_each = local.pool_cidrs

  ipam_pool_id = aws_vpc_ipam_pool.this[each.value.pool_key].id
  cidr         = each.value.cidr
}
