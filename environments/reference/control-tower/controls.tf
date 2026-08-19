# -----------------------------------------------------------------------------
# Control Tower Integration Boundary - Conceptual Metadata
#
# This file defines architecture metadata representing the Control Tower
# integration strategy. It contains NO aws_controltower_* resources and
# makes NO AWS API calls. It is purely informational Terraform that
# validates structurally and documents the governance model.
# -----------------------------------------------------------------------------

locals {
  # ---------------------------------------------------------------------------
  # Governed OUs
  # ---------------------------------------------------------------------------
  registered_ous = {
    Security            = { governed = true, notes = "Mandatory CT governance" }
    Infrastructure      = { governed = true, notes = "Network and shared services" }
    Workloads           = { governed = true, notes = "Parent for workload sub-OUs" }
    "Workloads/NonProd" = { governed = true, notes = "Development and staging" }
    "Workloads/Prod"    = { governed = true, notes = "Production with strict controls" }
    Sandbox             = { governed = true, notes = "Relaxed controls for experimentation" }
    Suspended           = { governed = false, notes = "Quarantine only - deny-all SCP, no CT enrollment" }
  }

  governed_ou_count   = length([for ou, cfg in local.registered_ous : ou if cfg.governed])
  ungoverned_ou_count = length([for ou, cfg in local.registered_ous : ou if !cfg.governed])

  # ---------------------------------------------------------------------------
  # Control Categories
  # ---------------------------------------------------------------------------
  control_categories = {
    mandatory = {
      description = "Controls applied by CT to all governed accounts automatically"
      owner       = "control-tower"
      examples    = ["deny-root-user-actions", "require-cloudtrail", "require-config"]
    }
    strongly_recommended = {
      description = "Controls CT recommends but does not force"
      owner       = "control-tower"
      examples    = ["deny-internet-gateway-creation", "require-mfa"]
    }
    elective = {
      description = "Optional CT controls enabled per-OU by platform team"
      owner       = "platform-team"
      examples    = ["deny-vpc-without-flowlogs", "restrict-instance-types"]
    }
    custom = {
      description = "Controls implemented via Terraform SCPs beyond CT catalog"
      owner       = "terraform"
      examples    = ["deny-unapproved-regions", "require-imdsv2"]
    }
  }

  # ---------------------------------------------------------------------------
  # Account Baseline Layers (execution order)
  # ---------------------------------------------------------------------------
  baseline_layers = [
    {
      layer       = 1
      name        = "control-tower-mandatory"
      owner       = "control-tower"
      description = "CT mandatory guardrails (org trail, baseline Config, SCPs)"
      terraform   = false
    },
    {
      layer       = 2
      name        = "organization-scp"
      owner       = "terraform"
      description = "Custom SCPs (region deny, IMDSv2, root user)"
      terraform   = true
      module      = "modules/scp"
    },
    {
      layer       = 3
      name        = "security-baseline"
      owner       = "terraform"
      description = "Config custom rules, GuardDuty, Security Hub"
      terraform   = true
      modules     = ["modules/config", "modules/guardduty", "modules/security-hub"]
    },
    {
      layer       = 4
      name        = "logging"
      owner       = "terraform"
      description = "Additional log storage and account-level trails"
      terraform   = true
      modules     = ["modules/log-archive", "modules/cloudtrail"]
    },
    {
      layer       = 5
      name        = "networking"
      owner       = "terraform"
      description = "IPAM allocation, VPC provisioning"
      terraform   = true
      modules     = ["modules/vpc-ipam", "modules/vpc"]
    },
    {
      layer       = 6
      name        = "identity"
      owner       = "terraform"
      description = "Permission sets and account assignments"
      terraform   = true
      module      = "modules/identity-center"
    },
    {
      layer       = 7
      name        = "workload"
      owner       = "application-team"
      description = "Application-specific resources"
      terraform   = true
    },
  ]

  terraform_owned_layers = [for l in local.baseline_layers : l.name if l.terraform]

  # ---------------------------------------------------------------------------
  # Integration Boundaries
  # ---------------------------------------------------------------------------
  control_tower_owns = [
    "organization-trail",
    "baseline-config-recorder",
    "mandatory-scps",
    "landing-zone-roles",
    "ct-log-archive-bucket",
    "account-enrollment",
    "landing-zone-settings",
  ]

  terraform_owns = [
    "custom-scps",
    "custom-config-rules",
    "guardduty-detector",
    "security-hub-standards",
    "platform-log-archive",
    "account-level-trails",
    "ipam-pools",
    "vpc-provisioning",
    "permission-sets",
    "account-assignments",
  ]

  # ---------------------------------------------------------------------------
  # Module Compatibility Assessment
  # ---------------------------------------------------------------------------
  module_compatibility = {
    organization = {
      status = "requires-adjustment"
      notes  = "In CT environment, use data sources for existing org/OUs instead of creating"
    }
    scp = {
      status = "compatible"
      notes  = "Custom SCPs supplement CT controls; audit for overlap before deployment"
    }
    config = {
      status = "compatible"
      notes  = "Adds custom rules on top of CT baseline recorder"
    }
    guardduty = {
      status = "compatible"
      notes  = "Account-level detector; future org-admin is separate module"
    }
    security_hub = {
      status = "compatible"
      notes  = "CT enables SecurityHub; module adds custom standards/overrides"
    }
    log_archive = {
      status = "compatible"
      notes  = "Platform bucket supplements CT-managed log archive bucket"
    }
    cloudtrail = {
      status = "optional-with-ct"
      notes  = "CT org trail replaces need for account trails; module available for supplementary"
    }
    vpc = {
      status = "compatible"
      notes  = "No CT overlap; networking is platform responsibility"
    }
    vpc_ipam = {
      status = "compatible"
      notes  = "No CT overlap; IPAM is platform responsibility"
    }
    identity_center = {
      status = "compatible"
      notes  = "Manages custom permission sets; must not conflict with CT-created sets"
    }
  }
}
