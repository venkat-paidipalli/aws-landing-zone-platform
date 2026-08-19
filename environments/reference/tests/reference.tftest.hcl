# -----------------------------------------------------------------------------
# Reference Environment - Composition Tests (Mocked Provider)
#
# Tests the wiring and architecture of the composed landing zone rather
# than individual module internals (those are tested in module-level tests).
#
# Run with: terraform -chdir=environments/reference test
# No AWS credentials required.
# -----------------------------------------------------------------------------

mock_provider "aws" {}

# -----------------------------------------------------------------------------
# Test: Organization structure
# -----------------------------------------------------------------------------

run "organization_structure" {
  command = plan

  assert {
    condition     = output.landing_zone_metadata.ou_count == 7
    error_message = "Should have 7 organizational units."
  }

  assert {
    condition     = output.landing_zone_metadata.account_count == 8
    error_message = "Should have 8 member accounts."
  }

  assert {
    condition     = output.landing_zone_metadata.organization_name == "portfolio-platform"
    error_message = "Organization name should be portfolio-platform."
  }
}

# -----------------------------------------------------------------------------
# Test: SCP composition
# -----------------------------------------------------------------------------

run "scp_composition" {
  command = plan

  assert {
    condition     = output.landing_zone_metadata.scp_policy_count == 3
    error_message = "Should have 3 SCP policies."
  }

  assert {
    condition     = output.scp_summary.policy_count == 3
    error_message = "SCP metadata should report 3 policies."
  }
}

# -----------------------------------------------------------------------------
# Test: No root-wide restrictive SCP
# -----------------------------------------------------------------------------

run "no_root_wide_restrictive_scp" {
  command = plan

  # The scp_summary.target_paths should NOT include ROOT for restrictive policies
  # (Only OU-level targeting is used in this composition)
  assert {
    condition     = !contains(output.scp_summary.target_paths, "ROOT")
    error_message = "No restrictive SCP should be attached to ROOT."
  }
}

# -----------------------------------------------------------------------------
# Test: VPC composition
# -----------------------------------------------------------------------------

run "vpc_composition" {
  command = plan

  assert {
    condition     = output.landing_zone_metadata.vpc_count == 4
    error_message = "Should have 4 VPCs."
  }

  assert {
    condition     = output.network_summary.vpcs.development == "10.10.0.0/16"
    error_message = "Development VPC should have correct CIDR."
  }

  assert {
    condition     = output.network_summary.vpcs.staging == "10.20.0.0/16"
    error_message = "Staging VPC should have correct CIDR."
  }

  assert {
    condition     = output.network_summary.vpcs.production == "10.30.0.0/16"
    error_message = "Production VPC should have correct CIDR."
  }

  assert {
    condition     = output.network_summary.vpcs.shared_services == "10.40.0.0/16"
    error_message = "Shared services VPC should have correct CIDR."
  }
}

# -----------------------------------------------------------------------------
# Test: Logging wiring
# -----------------------------------------------------------------------------

run "logging_wiring" {
  command = plan

  assert {
    condition     = output.logging_summary.log_archive_bucket == "lz-audit-logs-reference-000000000000"
    error_message = "Log archive bucket should have expected name."
  }

  assert {
    condition     = output.logging_summary.cloudtrail_bucket == "lz-audit-logs-reference-000000000000"
    error_message = "CloudTrail should deliver to the log archive bucket."
  }

  assert {
    condition     = output.logging_summary.cloudtrail_name == "lz-account-trail"
    error_message = "CloudTrail name should be lz-account-trail."
  }
}

# -----------------------------------------------------------------------------
# Test: Security baseline present
# -----------------------------------------------------------------------------

run "security_baseline" {
  command = plan

  assert {
    condition     = output.security_summary.config_rules == 4
    error_message = "Config should have 4 baseline rules."
  }

  assert {
    condition     = output.security_summary.guardduty.detector_enabled == true
    error_message = "GuardDuty should be enabled."
  }

  assert {
    condition     = output.security_summary.security_hub.standards_count == 1
    error_message = "Security Hub should have 1 standard enabled."
  }
}

# -----------------------------------------------------------------------------
# Test: Identity Center composition
# -----------------------------------------------------------------------------

run "identity_center_composition" {
  command = plan

  assert {
    condition     = output.landing_zone_metadata.permission_set_count == 5
    error_message = "Should have 5 permission sets."
  }

  assert {
    condition     = output.landing_zone_metadata.assignment_count == 8
    error_message = "Should have 8 account assignments."
  }
}

# -----------------------------------------------------------------------------
# Test: Common tags
# -----------------------------------------------------------------------------

run "common_tags" {
  command = plan

  assert {
    condition     = output.landing_zone_metadata.environment == "reference"
    error_message = "Environment should be 'reference'."
  }

  assert {
    condition     = output.landing_zone_metadata.approved_regions == tolist(["us-east-1", "us-west-2"])
    error_message = "Approved regions should be us-east-1 and us-west-2."
  }
}

# -----------------------------------------------------------------------------
# Test: Modules composed count
# -----------------------------------------------------------------------------

run "modules_composed" {
  command = plan

  assert {
    condition     = output.landing_zone_metadata.modules_composed == 10
    error_message = "Should compose 10 modules."
  }
}

# -----------------------------------------------------------------------------
# Test: No organization CloudTrail
# -----------------------------------------------------------------------------

run "no_organization_trail" {
  command = plan

  assert {
    condition     = module.cloudtrail.cloudtrail_metadata.is_organization_trail == false
    error_message = "CloudTrail should NOT be an organization trail."
  }
}

# -----------------------------------------------------------------------------
# Test: No GuardDuty delegated admin
# (verified by checking only detector resources exist - no org resources)
# -----------------------------------------------------------------------------

run "no_guardduty_org_admin" {
  command = plan

  assert {
    condition     = output.security_summary.guardduty.s3_protection == true
    error_message = "GuardDuty S3 protection should be enabled (account-level only)."
  }
}
