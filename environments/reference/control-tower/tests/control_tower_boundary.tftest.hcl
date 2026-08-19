# -----------------------------------------------------------------------------
# Control Tower Boundary - Architecture Metadata Tests
#
# Validates the governance boundary model without AWS API calls.
# Tests architecture invariants, not AWS resources.
#
# Run with: terraform -chdir=environments/reference/control-tower test
# No AWS credentials required. No provider needed.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Test: Governed OUs
# -----------------------------------------------------------------------------

run "governed_ou_count" {
  command = plan

  assert {
    condition     = output.governed_ou_count == 6
    error_message = "Should have 6 governed OUs."
  }
}

run "suspended_not_governed" {
  command = plan

  assert {
    condition     = output.governed_ous["Suspended"].governed == false
    error_message = "Suspended OU should NOT be governed by Control Tower."
  }
}

run "security_governed" {
  command = plan

  assert {
    condition     = output.governed_ous["Security"].governed == true
    error_message = "Security OU should be governed."
  }
}

run "workloads_prod_governed" {
  command = plan

  assert {
    condition     = output.governed_ous["Workloads/Prod"].governed == true
    error_message = "Workloads/Prod OU should be governed."
  }
}

# -----------------------------------------------------------------------------
# Test: Baseline layer ordering
# -----------------------------------------------------------------------------

run "baseline_has_seven_layers" {
  command = plan

  assert {
    condition     = length(output.baseline_layers) == 7
    error_message = "Should have 7 baseline layers."
  }
}

run "ct_mandatory_is_first_layer" {
  command = plan

  assert {
    condition     = output.baseline_layers[0].name == "control-tower-mandatory"
    error_message = "Control Tower mandatory should be layer 1."
  }

  assert {
    condition     = output.baseline_layers[0].owner == "control-tower"
    error_message = "Layer 1 should be owned by Control Tower."
  }
}

run "custom_scp_is_second_layer" {
  command = plan

  assert {
    condition     = output.baseline_layers[1].name == "organization-scp"
    error_message = "Custom SCPs should be layer 2."
  }

  assert {
    condition     = output.baseline_layers[1].owner == "terraform"
    error_message = "Layer 2 should be owned by Terraform."
  }
}

run "security_baseline_layer_exists" {
  command = plan

  assert {
    condition     = output.baseline_layers[2].name == "security-baseline"
    error_message = "Security baseline should be layer 3."
  }
}

run "networking_layer_exists" {
  command = plan

  assert {
    condition     = output.baseline_layers[4].name == "networking"
    error_message = "Networking should be layer 5."
  }
}

run "identity_layer_exists" {
  command = plan

  assert {
    condition     = output.baseline_layers[5].name == "identity"
    error_message = "Identity should be layer 6."
  }
}

# -----------------------------------------------------------------------------
# Test: Ownership boundaries
# -----------------------------------------------------------------------------

run "ct_ownership_declared" {
  command = plan

  assert {
    condition     = length(output.control_tower_owns) >= 5
    error_message = "Control Tower should own at least 5 resource categories."
  }

  assert {
    condition     = contains(output.control_tower_owns, "organization-trail")
    error_message = "CT should own organization-trail."
  }

  assert {
    condition     = contains(output.control_tower_owns, "mandatory-scps")
    error_message = "CT should own mandatory-scps."
  }
}

run "terraform_ownership_declared" {
  command = plan

  assert {
    condition     = length(output.terraform_owns) >= 8
    error_message = "Terraform should own at least 8 resource categories."
  }

  assert {
    condition     = contains(output.terraform_owns, "custom-scps")
    error_message = "Terraform should own custom-scps."
  }

  assert {
    condition     = contains(output.terraform_owns, "vpc-provisioning")
    error_message = "Terraform should own vpc-provisioning."
  }

  assert {
    condition     = contains(output.terraform_owns, "permission-sets")
    error_message = "Terraform should own permission-sets."
  }
}

# -----------------------------------------------------------------------------
# Test: Module compatibility
# -----------------------------------------------------------------------------

run "all_modules_assessed" {
  command = plan

  assert {
    condition     = output.boundary_metadata.modules_assessed == 10
    error_message = "All 10 modules should be assessed for CT compatibility."
  }
}

run "organization_requires_adjustment" {
  command = plan

  assert {
    condition     = output.module_compatibility["organization"].status == "requires-adjustment"
    error_message = "Organization module should require adjustment for CT."
  }
}

run "scp_compatible" {
  command = plan

  assert {
    condition     = output.module_compatibility["scp"].status == "compatible"
    error_message = "SCP module should be compatible with CT."
  }
}

run "cloudtrail_optional_with_ct" {
  command = plan

  assert {
    condition     = output.module_compatibility["cloudtrail"].status == "optional-with-ct"
    error_message = "CloudTrail module should be optional when CT org trail exists."
  }
}

run "vpc_compatible" {
  command = plan

  assert {
    condition     = output.module_compatibility["vpc"].status == "compatible"
    error_message = "VPC module should be compatible (no CT overlap)."
  }
}

# -----------------------------------------------------------------------------
# Test: No CT deployment resources
# -----------------------------------------------------------------------------

run "ct_not_deployed" {
  command = plan

  assert {
    condition     = output.boundary_metadata.ct_deployed == false
    error_message = "Control Tower should NOT be marked as deployed."
  }

  assert {
    condition     = output.boundary_metadata.aft_deployed == false
    error_message = "AFT should NOT be marked as deployed."
  }
}

# -----------------------------------------------------------------------------
# Test: Control categories
# -----------------------------------------------------------------------------

run "four_control_categories" {
  command = plan

  assert {
    condition     = output.boundary_metadata.control_categories == 4
    error_message = "Should have 4 control categories."
  }
}

# -----------------------------------------------------------------------------
# Test: Summary metadata
# -----------------------------------------------------------------------------

run "boundary_summary" {
  command = plan

  assert {
    condition     = output.boundary_metadata.governed_ous == 6
    error_message = "Metadata should report 6 governed OUs."
  }

  assert {
    condition     = output.boundary_metadata.ungoverned_ous == 1
    error_message = "Metadata should report 1 ungoverned OU (Suspended)."
  }

  assert {
    condition     = output.boundary_metadata.baseline_layers == 7
    error_message = "Metadata should report 7 baseline layers."
  }
}
