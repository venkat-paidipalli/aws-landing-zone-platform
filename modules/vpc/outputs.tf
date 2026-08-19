# -----------------------------------------------------------------------------
# VPC Module - Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC."
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "subnet_ids" {
  description = "Map of subnet key to subnet ID."
  value = {
    for key, subnet in aws_subnet.this : key => subnet.id
  }
}

output "subnet_cidr_blocks" {
  description = "Map of subnet key to subnet CIDR block."
  value = {
    for key, subnet in aws_subnet.this : key => subnet.cidr_block
  }
}

output "subnet_arns" {
  description = "Map of subnet key to subnet ARN."
  value = {
    for key, subnet in aws_subnet.this : key => subnet.arn
  }
}

output "route_table_ids" {
  description = "Map of route table type to route table ID."
  value = merge(
    length(aws_route_table.public) > 0 ? { "public" = aws_route_table.public[0].id } : {},
    length(aws_route_table.private) > 0 ? { "private" = aws_route_table.private[0].id } : {},
  )
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway (null if not created)."
  value       = length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].id : null
}

output "vpc_metadata" {
  description = "Summary metadata about the VPC configuration."
  value = {
    vpc_cidr             = var.vpc_cidr_block
    vpc_name             = var.vpc_name
    dns_support          = var.enable_dns_support
    dns_hostnames        = var.enable_dns_hostnames
    subnet_count         = length(var.subnets)
    public_subnet_count  = length(local.public_subnets)
    private_subnet_count = length(local.private_subnets)
    internet_gateway     = var.create_internet_gateway
    flow_logs_enabled    = var.enable_flow_logs
  }
}
