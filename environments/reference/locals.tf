# -----------------------------------------------------------------------------
# Reference Environment - Locals
#
# Centralizes configuration for the reference landing zone composition.
# All values are FICTIONAL for portfolio demonstration.
# -----------------------------------------------------------------------------

locals {
  # ---------------------------------------------------------------------------
  # Common Tags
  # ---------------------------------------------------------------------------
  common_tags = {
    Project     = "aws-landing-zone-platform"
    Environment = var.environment_name
    ManagedBy   = "terraform"
    Owner       = "platform-team"
    CostCenter  = "portfolio"
  }

  # ---------------------------------------------------------------------------
  # Organization Model
  # ---------------------------------------------------------------------------
  organization_name = "portfolio-platform"

  organizational_units = {
    Security            = { parent = "ROOT", description = "Security foundation accounts" }
    Infrastructure      = { parent = "ROOT", description = "Shared infrastructure accounts" }
    Workloads           = { parent = "ROOT", description = "Application workload accounts" }
    "Workloads/NonProd" = { parent = "Workloads", description = "Non-production workloads" }
    "Workloads/Prod"    = { parent = "Workloads", description = "Production workloads" }
    Sandbox             = { parent = "ROOT", description = "Experimentation and learning" }
    Suspended           = { parent = "ROOT", description = "Quarantined or decommissioned accounts" }
  }

  accounts = {
    security_tooling = {
      name    = "lz-security-tooling"
      email   = "aws+security@example.invalid"
      ou_path = "Security"
      tags    = { AccountRole = "security-tooling" }
    }
    log_archive = {
      name    = "lz-log-archive"
      email   = "aws+log-archive@example.invalid"
      ou_path = "Security"
      tags    = { AccountRole = "log-archive" }
    }
    network = {
      name    = "lz-network"
      email   = "aws+network@example.invalid"
      ou_path = "Infrastructure"
      tags    = { AccountRole = "network" }
    }
    shared_services = {
      name    = "lz-shared-services"
      email   = "aws+shared-services@example.invalid"
      ou_path = "Infrastructure"
      tags    = { AccountRole = "shared-services" }
    }
    sandbox = {
      name    = "lz-sandbox"
      email   = "aws+sandbox@example.invalid"
      ou_path = "Sandbox"
      tags    = { AccountRole = "sandbox" }
    }
    development = {
      name    = "lz-development"
      email   = "aws+development@example.invalid"
      ou_path = "Workloads/NonProd"
      tags    = { AccountRole = "development" }
    }
    staging = {
      name    = "lz-staging"
      email   = "aws+staging@example.invalid"
      ou_path = "Workloads/NonProd"
      tags    = { AccountRole = "staging" }
    }
    production = {
      name    = "lz-production"
      email   = "aws+production@example.invalid"
      ou_path = "Workloads/Prod"
      tags    = { AccountRole = "production" }
    }
  }

  # ---------------------------------------------------------------------------
  # SCP Targeting Strategy
  # ---------------------------------------------------------------------------
  # deny-root-user: All OUs except Security (security team may need root for
  #   incident response in the security-tooling account)
  # deny-unapproved-regions: Workload + Sandbox OUs (Infrastructure/Security
  #   may need global operations)
  # require-imdsv2: Workload OUs only (where EC2 instances run)

  scp_deny_root_targets   = ["Infrastructure", "Workloads/NonProd", "Workloads/Prod", "Sandbox"]
  scp_region_deny_targets = ["Workloads/NonProd", "Workloads/Prod", "Sandbox"]
  scp_imdsv2_targets      = ["Workloads/NonProd", "Workloads/Prod"]

  # ---------------------------------------------------------------------------
  # Network Address Plan (IPAM)
  # ---------------------------------------------------------------------------
  cidr_plan = {
    development     = "10.10.0.0/16"
    staging         = "10.20.0.0/16"
    production      = "10.30.0.0/16"
    shared_services = "10.40.0.0/16"
    network         = "10.50.0.0/16"
    sandbox         = "10.60.0.0/16"
  }

  # ---------------------------------------------------------------------------
  # Subnet Templates (2-AZ, private + data)
  # ---------------------------------------------------------------------------
  workload_subnets = { for name, cidr in {
    development     = local.cidr_plan.development
    staging         = local.cidr_plan.staging
    production      = local.cidr_plan.production
    shared_services = local.cidr_plan.shared_services
    } : name => {
    "private-a" = { cidr_block = cidrsubnet(cidr, 8, 1), availability_zone = "us-east-1a" }
    "private-b" = { cidr_block = cidrsubnet(cidr, 8, 2), availability_zone = "us-east-1b" }
    "data-a"    = { cidr_block = cidrsubnet(cidr, 8, 11), availability_zone = "us-east-1a", tags = { Tier = "data" } }
    "data-b"    = { cidr_block = cidrsubnet(cidr, 8, 12), availability_zone = "us-east-1b", tags = { Tier = "data" } }
    }
  }

  # ---------------------------------------------------------------------------
  # Security Baseline - Config Rules
  # ---------------------------------------------------------------------------
  config_baseline_rules = {
    s3_public_read = {
      name              = "s3-bucket-public-read-prohibited"
      source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
      description       = "Checks S3 buckets do not allow public read"
    }
    encrypted_volumes = {
      name              = "encrypted-volumes"
      source_identifier = "ENCRYPTED_VOLUMES"
      description       = "Checks EBS volumes are encrypted"
    }
    root_mfa = {
      name                        = "root-account-mfa-enabled"
      source_identifier           = "ROOT_ACCOUNT_MFA_ENABLED"
      description                 = "Checks root account has MFA"
      maximum_execution_frequency = "TwentyFour_Hours"
    }
    cloudtrail_enabled = {
      name                        = "cloudtrail-enabled"
      source_identifier           = "CLOUD_TRAIL_ENABLED"
      description                 = "Checks CloudTrail is enabled"
      maximum_execution_frequency = "TwentyFour_Hours"
    }
  }

  # ---------------------------------------------------------------------------
  # Identity Center - Permission Sets
  # ---------------------------------------------------------------------------
  sso_instance_arn = "arn:aws:sso:::instance/ssoins-0000000000000001"

  permission_sets = {
    readonly = {
      name                 = "ReadOnly"
      description          = "Read-only access across all services"
      session_duration     = "PT1H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
    developer = {
      name                 = "Developer"
      description          = "Developer workload access"
      session_duration     = "PT4H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/PowerUserAccess"]
    }
    security_audit = {
      name                 = "SecurityAudit"
      description          = "Security and compliance read access"
      session_duration     = "PT1H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/SecurityAudit"]
    }
    network_admin = {
      name                 = "NetworkAdmin"
      description          = "Network operations access"
      session_duration     = "PT4H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/job-function/NetworkAdministrator"]
    }
    platform_admin = {
      name                 = "PlatformAdmin"
      description          = "Elevated platform administration"
      session_duration     = "PT1H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid      = "DenyDangerousActions"
          Effect   = "Deny"
          Action   = ["organizations:LeaveOrganization", "organizations:DeleteOrganization"]
          Resource = "*"
        }]
      })
    }
  }

  # Synthetic group principal IDs (fictional UUIDs)
  group_ids = {
    platform_admins = "a1a1a1a1-b2b2-c3c3-d4d4-e5e5e5e5e5e5"
    security_team   = "b2b2b2b2-c3c3-d4d4-e5e5-f6f6f6f6f6f6"
    network_team    = "c3c3c3c3-d4d4-e5e5-f6f6-a7a7a7a7a7a7"
    developers      = "d4d4d4d4-e5e5-f6f6-a7a7-b8b8b8b8b8b8"
    auditors        = "e5e5e5e5-f6f6-a7a7-b8b8-c9c9c9c9c9c9"
  }
}
