# -----------------------------------------------------------------------------
# Organization Module - Terraform Native Tests (Mocked Provider)
#
# These tests validate the organization module's logic without making any
# AWS API calls. The mock_provider block intercepts all AWS resource
# operations and returns synthetic data.
#
# Run with: terraform -chdir=modules/organization test
# No AWS credentials required.
# -----------------------------------------------------------------------------

mock_provider "aws" {}

# -----------------------------------------------------------------------------
# Variables shared across test runs
# -----------------------------------------------------------------------------

variables {
  organization_name = "portfolio-platform"
  feature_set       = "ALL"

  organizational_units = {
    Security = {
      parent      = "ROOT"
      description = "Security foundation accounts"
      tags        = { CostCenter = "cc-security" }
    }
    Infrastructure = {
      parent      = "ROOT"
      description = "Shared infrastructure accounts"
      tags        = { CostCenter = "cc-infrastructure" }
    }
    Workloads = {
      parent      = "ROOT"
      description = "Application workload accounts"
      tags        = { CostCenter = "cc-workloads" }
    }
    "Workloads/NonProd" = {
      parent      = "Workloads"
      description = "Non-production workload accounts"
      tags        = { CostCenter = "cc-workloads" }
    }
    "Workloads/Prod" = {
      parent      = "Workloads"
      description = "Production workload accounts"
      tags        = { CostCenter = "cc-workloads" }
    }
    Sandbox = {
      parent      = "ROOT"
      description = "Experimentation and learning"
      tags        = { CostCenter = "cc-sandbox" }
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
      tags    = { Environment = "production", Project = "landing-zone" }
    }
    log_archive = {
      name    = "lz-log-archive"
      email   = "aws+log-archive@example.invalid"
      ou_path = "Security"
      tags    = { Environment = "production", Project = "landing-zone" }
    }
    network = {
      name    = "lz-network"
      email   = "aws+network@example.invalid"
      ou_path = "Infrastructure"
      tags    = { Environment = "production", Project = "landing-zone" }
    }
    shared_services = {
      name    = "lz-shared-services"
      email   = "aws+shared-services@example.invalid"
      ou_path = "Infrastructure"
      tags    = { Environment = "production", Project = "landing-zone" }
    }
    sandbox = {
      name    = "lz-sandbox"
      email   = "aws+sandbox@example.invalid"
      ou_path = "Sandbox"
      tags    = { Environment = "sandbox", Project = "landing-zone" }
    }
    development = {
      name    = "lz-development"
      email   = "aws+development@example.invalid"
      ou_path = "Workloads/NonProd"
      tags    = { Environment = "development", Project = "landing-zone" }
    }
    staging = {
      name    = "lz-staging"
      email   = "aws+staging@example.invalid"
      ou_path = "Workloads/NonProd"
      tags    = { Environment = "staging", Project = "landing-zone" }
    }
    production = {
      name    = "lz-production"
      email   = "aws+production@example.invalid"
      ou_path = "Workloads/Prod"
      tags    = { Environment = "production", Project = "landing-zone" }
    }
  }
}

# -----------------------------------------------------------------------------
# Test: Organization metadata output
# -----------------------------------------------------------------------------

run "organization_metadata_is_correct" {
  command = plan

  assert {
    condition     = output.organization_metadata.name == "portfolio-platform"
    error_message = "Organization name should be 'portfolio-platform'."
  }

  assert {
    condition     = output.organization_metadata.feature_set == "ALL"
    error_message = "Feature set should be 'ALL'."
  }

  assert {
    condition     = output.organization_metadata.ou_count == 7
    error_message = "Should have 7 organizational units."
  }

  assert {
    condition     = output.organization_metadata.account_count == 8
    error_message = "Should have 8 member accounts."
  }
}

# -----------------------------------------------------------------------------
# Test: Organization resource configuration
# -----------------------------------------------------------------------------

run "organization_feature_set" {
  command = plan

  assert {
    condition     = aws_organizations_organization.this.feature_set == "ALL"
    error_message = "Organization feature_set should be 'ALL'."
  }
}

# -----------------------------------------------------------------------------
# Test: Top-level OUs created correctly
# -----------------------------------------------------------------------------

run "top_level_ous_created" {
  command = plan

  assert {
    condition     = length(aws_organizations_organizational_unit.top_level) == 5
    error_message = "Should create 5 top-level OUs (Security, Infrastructure, Workloads, Sandbox, Suspended)."
  }

  assert {
    condition     = aws_organizations_organizational_unit.top_level["Security"].name == "Security"
    error_message = "Security OU should have name 'Security'."
  }

  assert {
    condition     = aws_organizations_organizational_unit.top_level["Infrastructure"].name == "Infrastructure"
    error_message = "Infrastructure OU should have name 'Infrastructure'."
  }

  assert {
    condition     = aws_organizations_organizational_unit.top_level["Workloads"].name == "Workloads"
    error_message = "Workloads OU should have name 'Workloads'."
  }

  assert {
    condition     = aws_organizations_organizational_unit.top_level["Sandbox"].name == "Sandbox"
    error_message = "Sandbox OU should have name 'Sandbox'."
  }

  assert {
    condition     = aws_organizations_organizational_unit.top_level["Suspended"].name == "Suspended"
    error_message = "Suspended OU should have name 'Suspended'."
  }
}

# -----------------------------------------------------------------------------
# Test: Nested OUs created correctly
# -----------------------------------------------------------------------------

run "nested_ous_created" {
  command = plan

  assert {
    condition     = length(aws_organizations_organizational_unit.nested) == 2
    error_message = "Should create 2 nested OUs (Workloads/NonProd, Workloads/Prod)."
  }

  assert {
    condition     = aws_organizations_organizational_unit.nested["Workloads/NonProd"].name == "NonProd"
    error_message = "Workloads/NonProd OU should have display name 'NonProd'."
  }

  assert {
    condition     = aws_organizations_organizational_unit.nested["Workloads/Prod"].name == "Prod"
    error_message = "Workloads/Prod OU should have display name 'Prod'."
  }
}

# -----------------------------------------------------------------------------
# Test: OU tagging includes module-generated tags
# -----------------------------------------------------------------------------

run "ou_tags_include_managed_by" {
  command = plan

  assert {
    condition     = aws_organizations_organizational_unit.top_level["Security"].tags["ManagedBy"] == "terraform"
    error_message = "Security OU should have ManagedBy=terraform tag."
  }

  assert {
    condition     = aws_organizations_organizational_unit.top_level["Security"].tags["OUPath"] == "Security"
    error_message = "Security OU should have OUPath=Security tag."
  }

  assert {
    condition     = aws_organizations_organizational_unit.top_level["Security"].tags["CostCenter"] == "cc-security"
    error_message = "Security OU should retain user-provided CostCenter tag."
  }
}

# -----------------------------------------------------------------------------
# Test: Member accounts created
# -----------------------------------------------------------------------------

run "accounts_created" {
  command = plan

  assert {
    condition     = length(aws_organizations_account.this) == 8
    error_message = "Should create 8 member accounts."
  }

  assert {
    condition     = aws_organizations_account.this["security"].name == "lz-security"
    error_message = "Security account should have name 'lz-security'."
  }

  assert {
    condition     = aws_organizations_account.this["production"].name == "lz-production"
    error_message = "Production account should have name 'lz-production'."
  }
}

# -----------------------------------------------------------------------------
# Test: Account safety configuration
# -----------------------------------------------------------------------------

run "accounts_have_safe_deletion_config" {
  command = plan

  assert {
    condition     = aws_organizations_account.this["security"].close_on_deletion == false
    error_message = "Accounts should have close_on_deletion=false for safety."
  }

  assert {
    condition     = aws_organizations_account.this["production"].close_on_deletion == false
    error_message = "Production account should have close_on_deletion=false."
  }

  assert {
    condition     = aws_organizations_account.this["sandbox"].close_on_deletion == false
    error_message = "Sandbox account should have close_on_deletion=false."
  }
}

# -----------------------------------------------------------------------------
# Test: Account role names
# -----------------------------------------------------------------------------

run "accounts_have_correct_role_name" {
  command = plan

  assert {
    condition     = aws_organizations_account.this["security"].role_name == "OrganizationAccountAccessRole"
    error_message = "Default role_name should be 'OrganizationAccountAccessRole'."
  }
}

# -----------------------------------------------------------------------------
# Test: Account tagging includes module-generated tags
# -----------------------------------------------------------------------------

run "account_tags_include_managed_by" {
  command = plan

  assert {
    condition     = aws_organizations_account.this["security"].tags["ManagedBy"] == "terraform"
    error_message = "Account should have ManagedBy=terraform tag."
  }

  assert {
    condition     = aws_organizations_account.this["security"].tags["AccountKey"] == "security"
    error_message = "Account should have AccountKey tag matching the map key."
  }

  assert {
    condition     = aws_organizations_account.this["security"].tags["Environment"] == "production"
    error_message = "Account should have Environment tag from user tags."
  }
}

# -----------------------------------------------------------------------------
# Test: Consolidated billing feature set
# -----------------------------------------------------------------------------

run "consolidated_billing_feature_set" {
  command = plan

  variables {
    feature_set = "CONSOLIDATED_BILLING"
  }

  assert {
    condition     = aws_organizations_organization.this.feature_set == "CONSOLIDATED_BILLING"
    error_message = "Organization should use CONSOLIDATED_BILLING when specified."
  }
}
