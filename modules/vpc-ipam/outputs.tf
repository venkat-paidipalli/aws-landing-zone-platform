# -----------------------------------------------------------------------------
# VPC IPAM Module - Outputs
# -----------------------------------------------------------------------------

output "ipam_id" {
  description = "The ID of the IPAM instance."
  value       = aws_vpc_ipam.this.id
}

output "ipam_arn" {
  description = "The ARN of the IPAM instance."
  value       = aws_vpc_ipam.this.arn
}

output "private_scope_id" {
  description = "The ID of the IPAM's private default scope."
  value       = aws_vpc_ipam.this.private_default_scope_id
}

output "pool_ids" {
  description = "Map of pool key to pool ID."
  value = {
    for key, pool in aws_vpc_ipam_pool.this : key => pool.id
  }
}

output "pool_arns" {
  description = "Map of pool key to pool ARN."
  value = {
    for key, pool in aws_vpc_ipam_pool.this : key => pool.arn
  }
}

output "pool_cidrs" {
  description = "Map of 'pool_key:cidr' to provisioned CIDR."
  value = {
    for key, pc in aws_vpc_ipam_pool_cidr.this : key => pc.cidr
  }
}

output "ipam_metadata" {
  description = "Summary metadata about the IPAM configuration."
  value = {
    operating_regions = var.operating_regions
    pool_count        = length(var.pools)
    total_cidrs       = length(local.pool_cidrs)
  }
}
