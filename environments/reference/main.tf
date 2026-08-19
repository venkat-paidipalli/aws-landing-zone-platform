# -----------------------------------------------------------------------------
# Reference Landing Zone Composition
#
# Composes all platform modules into a coherent multi-account landing zone.
# This is a REFERENCE environment for portfolio demonstration — it validates
# structurally but does not deploy to AWS.
#
# Architecture layers:
# 1. Organization (structure + accounts)
# 2. Governance (SCPs - preventive)
# 3. Networking (IPAM + VPCs)
# 4. Logging (S3 archive + CloudTrail)
# 5. Security (Config + GuardDuty + Security Hub)
# 6. Identity (Permission sets + Assignments)
# -----------------------------------------------------------------------------

# =============================================================================
# LAYER 1: ORGANIZATION STRUCTURE
# =============================================================================

module "organization" {
  source = "../../modules/organization"

  organization_name    = local.organization_name
  feature_set          = "ALL"
  organizational_units = local.organizational_units
  accounts             = local.accounts
}

# =============================================================================
# LAYER 2: GOVERNANCE (SCPs)
# =============================================================================

module "scp" {
  source = "../../modules/scp"

  approved_regions = var.approved_regions

  target_ids = merge(
    { "ROOT" = module.organization.root_id },
    module.organization.organizational_unit_ids
  )

  policies = {
    deny_root_user = {
      name        = "deny-root-user"
      description = "Deny all actions by root user in member accounts"
      content     = file("${path.module}/../../policies/scp/deny-root-user.json")
      targets     = local.scp_deny_root_targets
      tags        = { Scope = "baseline" }
    }
    deny_unapproved_regions = {
      name        = "deny-unapproved-regions"
      description = "Restrict operations to approved AWS regions"
      content     = module.scp.region_deny_policy_content
      targets     = local.scp_region_deny_targets
      tags        = { Scope = "baseline" }
    }
    require_imdsv2 = {
      name        = "require-imdsv2"
      description = "Require IMDSv2 for EC2 instance launches"
      content     = file("${path.module}/../../policies/scp/require-imdsv2.json")
      targets     = local.scp_imdsv2_targets
      tags        = { Scope = "baseline" }
    }
  }
}

# =============================================================================
# LAYER 3: NETWORKING
# =============================================================================

module "vpc_ipam" {
  source = "../../modules/vpc-ipam"

  operating_regions = var.approved_regions

  pools = {
    nonprod = {
      description = "Non-production workloads"
      locale      = "us-east-1"
      cidrs       = [local.cidr_plan.development, local.cidr_plan.staging]
    }
    prod = {
      description = "Production workloads"
      locale      = "us-east-1"
      cidrs       = [local.cidr_plan.production]
    }
    shared = {
      description = "Shared services and network"
      locale      = "us-east-1"
      cidrs       = [local.cidr_plan.shared_services, local.cidr_plan.network]
    }
    sandbox = {
      description = "Sandbox experimentation"
      locale      = "us-east-1"
      cidrs       = [local.cidr_plan.sandbox]
    }
  }

  tags = local.common_tags
}

module "vpc_development" {
  source = "../../modules/vpc"

  vpc_cidr_block = local.cidr_plan.development
  vpc_name       = "lz-development"
  subnets        = local.workload_subnets["development"]
  tags           = merge(local.common_tags, { AccountRole = "development" })
}

module "vpc_staging" {
  source = "../../modules/vpc"

  vpc_cidr_block = local.cidr_plan.staging
  vpc_name       = "lz-staging"
  subnets        = local.workload_subnets["staging"]
  tags           = merge(local.common_tags, { AccountRole = "staging" })
}

module "vpc_production" {
  source = "../../modules/vpc"

  vpc_cidr_block = local.cidr_plan.production
  vpc_name       = "lz-production"
  subnets        = local.workload_subnets["production"]
  tags           = merge(local.common_tags, { AccountRole = "production" })
}

module "vpc_shared_services" {
  source = "../../modules/vpc"

  vpc_cidr_block = local.cidr_plan.shared_services
  vpc_name       = "lz-shared-services"
  subnets        = local.workload_subnets["shared_services"]
  tags           = merge(local.common_tags, { AccountRole = "shared-services" })
}

# =============================================================================
# LAYER 4: LOGGING
# =============================================================================

module "log_archive" {
  source = "../../modules/log-archive"

  bucket_name     = "lz-audit-logs-reference-000000000000"
  encryption_type = "AES256"

  transition_to_ia_days      = 90
  transition_to_glacier_days = 365
  expiration_days            = 2555

  tags = merge(local.common_tags, { AccountRole = "log-archive" })
}

module "cloudtrail" {
  source = "../../modules/cloudtrail"

  trail_name     = "lz-account-trail"
  s3_bucket_name = module.log_archive.bucket_name
  s3_key_prefix  = "cloudtrail"

  tags = merge(local.common_tags, { Component = "audit" })
}

# =============================================================================
# LAYER 5: SECURITY BASELINE (representative account)
# =============================================================================

# Config baseline - representative for workload accounts
# In production, each account would have its own Config deployment.
module "config_baseline" {
  source = "../../modules/config"

  recorder_name      = "lz-config-recorder"
  recorder_role_arn  = "arn:aws:iam::555500001111:role/aws-config-recorder-role"
  delivery_s3_bucket = "lz-config-delivery-555500001111"

  snapshot_delivery_frequency = "Six_Hours"
  managed_rules               = local.config_baseline_rules
  tags                        = merge(local.common_tags, { Component = "config" })
}

# GuardDuty baseline - account-level detector
module "guardduty_baseline" {
  source = "../../modules/guardduty"

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  enable_s3_protection         = true
  enable_kubernetes_protection = false
  enable_malware_protection    = false

  tags = merge(local.common_tags, { Component = "guardduty" })
}

# Security Hub baseline - AWS Foundational standard
module "security_hub_baseline" {
  source = "../../modules/security-hub"

  enable_default_standards = false
  auto_enable_controls     = true

  standards = {
    aws_foundational = {
      arn = "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
    }
  }

  tags = merge(local.common_tags, { Component = "security-hub" })
}

# =============================================================================
# LAYER 6: IDENTITY & ACCESS
# =============================================================================

module "identity_center" {
  source = "../../modules/identity-center"

  instance_arn    = local.sso_instance_arn
  permission_sets = local.permission_sets
  tags            = local.common_tags

  assignments = {
    # Platform admins → security-tooling + network (not all accounts)
    platform_security = {
      permission_set_key = "platform_admin"
      principal_id       = local.group_ids.platform_admins
      principal_type     = "GROUP"
      target_account_id  = module.organization.account_ids["security_tooling"]
    }
    platform_network = {
      permission_set_key = "platform_admin"
      principal_id       = local.group_ids.platform_admins
      principal_type     = "GROUP"
      target_account_id  = module.organization.account_ids["network"]
    }

    # Security team → security-tooling + log-archive
    security_tooling = {
      permission_set_key = "security_audit"
      principal_id       = local.group_ids.security_team
      principal_type     = "GROUP"
      target_account_id  = module.organization.account_ids["security_tooling"]
    }
    security_logs = {
      permission_set_key = "security_audit"
      principal_id       = local.group_ids.security_team
      principal_type     = "GROUP"
      target_account_id  = module.organization.account_ids["log_archive"]
    }

    # Network team → network account
    network_ops = {
      permission_set_key = "network_admin"
      principal_id       = local.group_ids.network_team
      principal_type     = "GROUP"
      target_account_id  = module.organization.account_ids["network"]
    }

    # Developers → development + staging (NOT production)
    dev_development = {
      permission_set_key = "developer"
      principal_id       = local.group_ids.developers
      principal_type     = "GROUP"
      target_account_id  = module.organization.account_ids["development"]
    }
    dev_staging = {
      permission_set_key = "developer"
      principal_id       = local.group_ids.developers
      principal_type     = "GROUP"
      target_account_id  = module.organization.account_ids["staging"]
    }

    # Auditors → read-only on production
    audit_production = {
      permission_set_key = "readonly"
      principal_id       = local.group_ids.auditors
      principal_type     = "GROUP"
      target_account_id  = module.organization.account_ids["production"]
    }
  }
}
