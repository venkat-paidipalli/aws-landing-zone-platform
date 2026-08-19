# -----------------------------------------------------------------------------
# VPC Module - Main
#
# Creates a configurable VPC with subnets, route tables, and optional IGW.
# Designed for landing-zone workload and shared-services accounts.
#
# NOT in scope:
# - NAT Gateways (future, cost implications)
# - Transit Gateway attachments (separate module)
# - Network Firewall (separate module)
# - VPN/Direct Connect
# - Custom NACLs (relies on default + security groups + routing)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  instance_tenancy     = var.instance_tenancy

  tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Component = "vpc"
      Name      = var.vpc_name != "" ? var.vpc_name : null
    },
  )
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------

locals {
  public_subnets = {
    for key, subnet in var.subnets : key => subnet
    if subnet.public
  }

  private_subnets = {
    for key, subnet in var.subnets : key => subnet
    if !subnet.public
  }
}

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = merge(
    var.tags,
    each.value.tags,
    {
      ManagedBy = "terraform"
      Component = "vpc"
      SubnetKey = each.key
      Tier      = each.value.public ? "public" : "private"
    },
  )
}

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------

resource "aws_route_table" "public" {
  count  = length(local.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Component = "vpc"
      Name      = "public"
    },
  )
}

resource "aws_route_table" "private" {
  count  = length(local.private_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Component = "vpc"
      Name      = "private"
    },
  )
}

# -----------------------------------------------------------------------------
# Default Security Group - Restrict all traffic
#
# Every VPC has a default security group. If left unmanaged, it allows all
# traffic between members. This resource explicitly locks it down to deny
# all ingress and egress, ensuring workloads must use purpose-built SGs.
# -----------------------------------------------------------------------------

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  # No ingress or egress rules = deny all traffic
  tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Component = "vpc"
      Name      = "default-restricted"
    },
  )
}

# -----------------------------------------------------------------------------
# Route Table Associations
# -----------------------------------------------------------------------------

resource "aws_route_table_association" "public" {
  for_each = local.public_subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private[0].id
}

# -----------------------------------------------------------------------------
# Internet Gateway (optional)
# -----------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  count  = var.create_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Component = "vpc"
      Name      = "igw"
    },
  )
}

resource "aws_route" "public_internet" {
  count = var.create_internet_gateway && length(local.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

# -----------------------------------------------------------------------------
# VPC Flow Logs (optional)
# -----------------------------------------------------------------------------

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id               = aws_vpc.this.id
  traffic_type         = var.flow_logs_traffic_type
  log_destination_type = var.flow_logs_destination_type
  log_destination      = var.flow_logs_destination
  iam_role_arn         = var.flow_logs_destination_type == "cloud-watch-logs" ? var.flow_logs_iam_role_arn : null

  tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Component = "vpc"
      Name      = "flow-logs"
    },
  )
}
