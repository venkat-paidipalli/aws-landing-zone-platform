# -----------------------------------------------------------------------------
# VPC Module - Variable Definitions
# -----------------------------------------------------------------------------

variable "vpc_cidr_block" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "VPC CIDR block must be a valid IPv4 CIDR (e.g., '10.0.0.0/16')."
  }
}

variable "vpc_name" {
  description = "Name tag for the VPC."
  type        = string
  default     = ""
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "instance_tenancy" {
  description = "Instance tenancy option for the VPC."
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated", "host"], var.instance_tenancy)
    error_message = "Instance tenancy must be 'default', 'dedicated', or 'host'."
  }
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------

variable "subnets" {
  description = <<-EOT
    Map of subnets to create within the VPC.

    Map key: logical subnet identifier for Terraform referencing.

    Object attributes:
    - cidr_block:              Subnet CIDR (must be within VPC CIDR)
    - availability_zone:       AZ name (e.g., 'us-east-1a')
    - public:                  Whether this is a public subnet (affects route table)
    - map_public_ip_on_launch: Auto-assign public IPs to instances
    - tags:                    Additional tags for this subnet
  EOT
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    public                  = optional(bool, false)
    map_public_ip_on_launch = optional(bool, false)
    tags                    = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, subnet in var.subnets :
      can(cidrhost(subnet.cidr_block, 0))
    ])
    error_message = "Each subnet CIDR block must be a valid IPv4 CIDR."
  }

  validation {
    condition = alltrue([
      for key, subnet in var.subnets :
      can(regex("^[a-z]{2}(-[a-z]+-\\d+)[a-z]$", subnet.availability_zone))
    ])
    error_message = "Each availability zone must be a valid AZ name (e.g., 'us-east-1a')."
  }

  validation {
    condition     = length(distinct([for k, s in var.subnets : s.cidr_block])) == length(var.subnets)
    error_message = "Subnet CIDR blocks must be unique (no duplicates)."
  }

  validation {
    condition = alltrue([
      for key, subnet in var.subnets :
      alltrue([for tk, _ in subnet.tags : !startswith(tk, "aws:")])
    ])
    error_message = "Subnet tag keys must not use the reserved 'aws:' prefix."
  }
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------

variable "create_internet_gateway" {
  description = "Whether to create an Internet Gateway. Required for public subnets to reach the internet."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Flow Logs
# -----------------------------------------------------------------------------

variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs. If true, flow_logs_destination must be provided."
  type        = bool
  default     = false
}

variable "flow_logs_destination" {
  description = "ARN of the CloudWatch Logs group or S3 bucket for flow logs. Required when enable_flow_logs is true."
  type        = string
  default     = ""
}

variable "flow_logs_destination_type" {
  description = "Type of flow log destination: 'cloud-watch-logs' or 's3'."
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_logs_destination_type)
    error_message = "Flow logs destination type must be 'cloud-watch-logs' or 's3'."
  }
}

variable "flow_logs_iam_role_arn" {
  description = "IAM role ARN for flow logs delivery (required for cloud-watch-logs destination)."
  type        = string
  default     = ""
}

variable "flow_logs_traffic_type" {
  description = "Type of traffic to capture: ALL, ACCEPT, or REJECT."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.flow_logs_traffic_type)
    error_message = "Flow logs traffic type must be 'ALL', 'ACCEPT', or 'REJECT'."
  }
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key, _ in var.tags :
      !startswith(key, "aws:")
    ])
    error_message = "Tag keys must not use the reserved 'aws:' prefix."
  }
}
