# -----------------------------------------------------------------------------
# Identity Center Interface Test Fixture
#
# Demonstrates a realistic permission-set baseline with fictional values.
# All principal IDs, account IDs, and instance ARNs are SYNTHETIC.
# No AWS credentials required.
# -----------------------------------------------------------------------------

terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0, < 7.0" }
  }
}

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  access_key                  = "mock-access-key-for-validation"
  secret_key                  = "mock-secret-key-for-validation"
}

# NOTE: All IDs below are FICTIONAL/SYNTHETIC for portfolio testing.

module "identity_center" {
  source = "../../../modules/identity-center"

  instance_arn = "arn:aws:sso:::instance/ssoins-0000000000000001"

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
          Sid      = "DenyDangerousOrgActions"
          Effect   = "Deny"
          Action   = ["organizations:LeaveOrganization", "organizations:DeleteOrganization"]
          Resource = "*"
        }]
      })
    }
  }

  assignments = {
    readonly_all_dev = {
      permission_set_key = "readonly"
      principal_id       = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
      principal_type     = "GROUP"
      target_account_id  = "444455556666"
    }
    developer_dev = {
      permission_set_key = "developer"
      principal_id       = "b2c3d4e5-f6a7-8901-bcde-f12345678901"
      principal_type     = "GROUP"
      target_account_id  = "444455556666"
    }
    security_all = {
      permission_set_key = "security_audit"
      principal_id       = "c3d4e5f6-a7b8-9012-cdef-123456789012"
      principal_type     = "GROUP"
      target_account_id  = "111122223333"
    }
    platform_mgmt = {
      permission_set_key = "platform_admin"
      principal_id       = "d4e5f6a7-b8c9-0123-defa-234567890123"
      principal_type     = "GROUP"
      target_account_id  = "111122223333"
    }
  }

  tags = {
    Project     = "landing-zone"
    Environment = "management"
  }
}

output "permission_set_arns" {
  value = module.identity_center.permission_set_arns
}

output "metadata" {
  value = module.identity_center.identity_center_metadata
}
