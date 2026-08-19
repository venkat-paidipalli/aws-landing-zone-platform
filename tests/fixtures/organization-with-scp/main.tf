# -----------------------------------------------------------------------------
# Organization + SCP Integration Fixture
#
# Demonstrates how independently designed modules compose:
# - Organization module creates the org, OUs, and accounts
# - SCP module creates policies and attaches them to OUs
# - The only coupling is the target_ids map passed between them
#
# No AWS credentials required (uses provider with skip flags).
# -----------------------------------------------------------------------------

terraform {
  required_version = "~> 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  access_key = "mock-access-key-for-validation"
  secret_key = "mock-secret-key-for-validation"
}

# -----------------------------------------------------------------------------
# Organization Module
# -----------------------------------------------------------------------------

module "organization" {
  source = "../../../modules/organization"

  organization_name = "portfolio-platform"
  feature_set       = "ALL"

  organizational_units = {
    Security = {
      parent      = "ROOT"
      description = "Security foundation accounts"
    }
    Infrastructure = {
      parent      = "ROOT"
      description = "Shared infrastructure accounts"
    }
    Workloads = {
      parent      = "ROOT"
      description = "Application workload accounts"
    }
    "Workloads/NonProd" = {
      parent      = "Workloads"
      description = "Non-production workload accounts"
    }
    "Workloads/Prod" = {
      parent      = "Workloads"
      description = "Production workload accounts"
    }
    Sandbox = {
      parent      = "ROOT"
      description = "Experimentation and learning"
    }
    Suspended = {
      parent      = "ROOT"
      description = "Quarantined or decommissioned accounts"
    }
  }

  accounts = {
    security = {
      name    = "lz-security"
      email   = "aws+security@example.invalid"
      ou_path = "Security"
      tags    = { Environment = "production" }
    }
    log_archive = {
      name    = "lz-log-archive"
      email   = "aws+log-archive@example.invalid"
      ou_path = "Security"
      tags    = { Environment = "production" }
    }
    network = {
      name    = "lz-network"
      email   = "aws+network@example.invalid"
      ou_path = "Infrastructure"
      tags    = { Environment = "production" }
    }
    sandbox = {
      name    = "lz-sandbox"
      email   = "aws+sandbox@example.invalid"
      ou_path = "Sandbox"
      tags    = { Environment = "sandbox" }
    }
    development = {
      name    = "lz-development"
      email   = "aws+development@example.invalid"
      ou_path = "Workloads/NonProd"
      tags    = { Environment = "development" }
    }
    production = {
      name    = "lz-production"
      email   = "aws+production@example.invalid"
      ou_path = "Workloads/Prod"
      tags    = { Environment = "production" }
    }
  }
}

# -----------------------------------------------------------------------------
# SCP Module - wired to organization outputs
# -----------------------------------------------------------------------------

module "scp" {
  source = "../../../modules/scp"

  approved_regions = ["us-east-1", "us-west-2"]

  # Wire organization module outputs into SCP target resolution.
  # This is the only coupling point between the two modules.
  target_ids = merge(
    { "ROOT" = module.organization.root_id },
    module.organization.organizational_unit_ids
  )

  policies = {
    deny_root_user = {
      name        = "deny-root-user"
      description = "Deny all actions by root user in member accounts"
      content     = file("${path.module}/../../../policies/scp/deny-root-user.json")
      targets     = ["Security", "Infrastructure", "Workloads/NonProd", "Workloads/Prod", "Sandbox"]
      tags        = { Scope = "baseline" }
    }
    deny_unapproved_regions = {
      name        = "deny-unapproved-regions"
      description = "Restrict operations to approved AWS regions only"
      content     = module.scp.region_deny_policy_content
      targets     = ["Workloads/NonProd", "Workloads/Prod", "Sandbox"]
    }
    require_imdsv2 = {
      name        = "require-imdsv2"
      description = "Require IMDSv2 for all EC2 instance launches"
      content     = file("${path.module}/../../../policies/scp/require-imdsv2.json")
      targets     = ["Workloads/NonProd", "Workloads/Prod"]
    }
  }
}

# -----------------------------------------------------------------------------
# Outputs - demonstrate the integration wiring
# -----------------------------------------------------------------------------

output "organization_id" {
  value = module.organization.organization_id
}

output "ou_ids" {
  value = module.organization.organizational_unit_ids
}

output "scp_policy_ids" {
  value = module.scp.policy_ids
}

output "scp_attachments" {
  value = module.scp.policy_attachment_targets
}

output "scp_metadata" {
  value = module.scp.policy_metadata
}
