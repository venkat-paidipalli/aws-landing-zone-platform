# -----------------------------------------------------------------------------
# Organization Interface Test Fixture
#
# Instantiates the organization module with the full fictional landing zone
# configuration. This fixture is used for terraform validate (structural
# validation) only. It requires no AWS credentials.
#
# Note: terraform validate checks syntax and internal consistency but does
# NOT contact AWS APIs. The provider block is required to satisfy the
# provider requirement declared in the module.
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

  # No real credentials — this fixture is for structural validation only.
  access_key = "mock-access-key-for-validation"
  secret_key = "mock-secret-key-for-validation"
}

module "organization" {
  source = "../../../modules/organization"

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
      tags = {
        Environment        = "production"
        Project            = "landing-zone"
        DataClassification = "confidential"
      }
    }
    log_archive = {
      name    = "lz-log-archive"
      email   = "aws+log-archive@example.invalid"
      ou_path = "Security"
      tags = {
        Environment        = "production"
        Project            = "landing-zone"
        DataClassification = "confidential"
      }
    }
    network = {
      name    = "lz-network"
      email   = "aws+network@example.invalid"
      ou_path = "Infrastructure"
      tags = {
        Environment = "production"
        Project     = "landing-zone"
      }
    }
    shared_services = {
      name    = "lz-shared-services"
      email   = "aws+shared-services@example.invalid"
      ou_path = "Infrastructure"
      tags = {
        Environment = "production"
        Project     = "landing-zone"
      }
    }
    sandbox = {
      name    = "lz-sandbox"
      email   = "aws+sandbox@example.invalid"
      ou_path = "Sandbox"
      tags = {
        Environment = "sandbox"
        Project     = "landing-zone"
      }
    }
    development = {
      name    = "lz-development"
      email   = "aws+development@example.invalid"
      ou_path = "Workloads/NonProd"
      tags = {
        Environment = "development"
        Project     = "landing-zone"
      }
    }
    staging = {
      name    = "lz-staging"
      email   = "aws+staging@example.invalid"
      ou_path = "Workloads/NonProd"
      tags = {
        Environment = "staging"
        Project     = "landing-zone"
      }
    }
    production = {
      name    = "lz-production"
      email   = "aws+production@example.invalid"
      ou_path = "Workloads/Prod"
      tags = {
        Environment = "production"
        Project     = "landing-zone"
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Outputs for inspection
# -----------------------------------------------------------------------------

output "metadata" {
  value = module.organization.organization_metadata
}

output "ou_ids" {
  value = module.organization.organizational_unit_ids
}

output "account_ids" {
  value = module.organization.account_ids
}
