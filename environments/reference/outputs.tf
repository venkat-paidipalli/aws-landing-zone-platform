# -----------------------------------------------------------------------------
# Reference Environment - Outputs
#
# Exposes architecture summaries for documentation and testing.
# Does NOT output sensitive values (emails, secrets).
# -----------------------------------------------------------------------------

output "organization_summary" {
  description = "Organization structure summary."
  value = {
    organization_id = module.organization.organization_id
    root_id         = module.organization.root_id
    ou_count        = module.organization.organization_metadata.ou_count
    account_count   = module.organization.organization_metadata.account_count
  }
}

output "account_ids" {
  description = "Map of account logical key to AWS account ID."
  value       = module.organization.account_ids
}

output "ou_ids" {
  description = "Map of OU path to OU ID."
  value       = module.organization.organizational_unit_ids
}

output "scp_summary" {
  description = "SCP attachment summary."
  value       = module.scp.policy_metadata
}

output "network_summary" {
  description = "Network architecture summary."
  value = {
    ipam_id = module.vpc_ipam.ipam_id
    vpcs = {
      development     = module.vpc_development.vpc_cidr_block
      staging         = module.vpc_staging.vpc_cidr_block
      production      = module.vpc_production.vpc_cidr_block
      shared_services = module.vpc_shared_services.vpc_cidr_block
    }
  }
}

output "security_summary" {
  description = "Security baseline summary."
  value = {
    config_rules = module.config_baseline.config_metadata.rule_count
    guardduty    = module.guardduty_baseline.guardduty_metadata
    security_hub = module.security_hub_baseline.security_hub_metadata
  }
}

output "logging_summary" {
  description = "Logging architecture summary."
  value = {
    log_archive_bucket = module.log_archive.bucket_name
    cloudtrail_name    = module.cloudtrail.trail_name
    cloudtrail_bucket  = module.cloudtrail.cloudtrail_metadata.s3_bucket
  }
}

output "identity_summary" {
  description = "Identity and access summary."
  value = {
    permission_sets = module.identity_center.permission_set_names
    assignments     = module.identity_center.identity_center_metadata
  }
}

output "landing_zone_metadata" {
  description = "Overall landing zone architecture metadata."
  value = {
    environment          = var.environment_name
    approved_regions     = var.approved_regions
    organization_name    = local.organization_name
    ou_count             = 7
    account_count        = 8
    scp_policy_count     = 3
    vpc_count            = 4
    permission_set_count = 5
    assignment_count     = 8
    modules_composed     = 10
  }
}
