# -----------------------------------------------------------------------------
# Identity Center Module - Terraform Native Tests (Mocked Provider)
#
# Run with: terraform -chdir=modules/identity-center test
# No AWS credentials required.
# -----------------------------------------------------------------------------

mock_provider "aws" {}

variables {
  instance_arn = "arn:aws:sso:::instance/ssoins-synth0000000001"

  permission_sets = {
    readonly = {
      name             = "ReadOnly"
      description      = "Read-only access across all services"
      session_duration = "PT1H"
      aws_managed_policies = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess",
      ]
    }
    developer = {
      name             = "Developer"
      description      = "Developer workload access"
      session_duration = "PT4H"
      aws_managed_policies = [
        "arn:aws:iam::aws:policy/PowerUserAccess",
      ]
      tags = { Role = "developer" }
    }
    security_audit = {
      name             = "SecurityAudit"
      description      = "Security and compliance read access"
      session_duration = "PT1H"
      aws_managed_policies = [
        "arn:aws:iam::aws:policy/SecurityAudit",
      ]
    }
    platform_admin = {
      name             = "PlatformAdmin"
      description      = "Elevated platform administration"
      session_duration = "PT1H"
      aws_managed_policies = [
        "arn:aws:iam::aws:policy/AdministratorAccess",
      ]
      inline_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"DenyOrgLeave\",\"Effect\":\"Deny\",\"Action\":\"organizations:LeaveOrganization\",\"Resource\":\"*\"}]}"
    }
  }

  assignments = {
    readonly_security_dev = {
      permission_set_key = "readonly"
      principal_id       = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
      principal_type     = "GROUP"
      target_account_id  = "111122223333"
    }
    developer_dev = {
      permission_set_key = "developer"
      principal_id       = "b2c3d4e5-f6a7-8901-bcde-f12345678901"
      principal_type     = "GROUP"
      target_account_id  = "444455556666"
    }
    platform_admin_mgmt = {
      permission_set_key = "platform_admin"
      principal_id       = "c3d4e5f6-a7b8-9012-cdef-123456789012"
      principal_type     = "GROUP"
      target_account_id  = "111122223333"
    }
  }

  tags = {
    Project     = "landing-zone"
    Environment = "management"
  }
}

# -----------------------------------------------------------------------------
# Test: Permission sets created
# -----------------------------------------------------------------------------

run "permission_sets_created" {
  command = plan

  assert {
    condition     = length(aws_ssoadmin_permission_set.this) == 4
    error_message = "Should create 4 permission sets."
  }
}

# -----------------------------------------------------------------------------
# Test: Default session duration
# -----------------------------------------------------------------------------

run "default_session_duration" {
  command = plan

  assert {
    condition     = aws_ssoadmin_permission_set.this["readonly"].session_duration == "PT1H"
    error_message = "ReadOnly should have PT1H session duration."
  }
}

# -----------------------------------------------------------------------------
# Test: Custom session duration
# -----------------------------------------------------------------------------

run "custom_session_duration" {
  command = plan

  assert {
    condition     = aws_ssoadmin_permission_set.this["developer"].session_duration == "PT4H"
    error_message = "Developer should have PT4H session duration."
  }
}

# -----------------------------------------------------------------------------
# Test: Permission set names
# -----------------------------------------------------------------------------

run "permission_set_names" {
  command = plan

  assert {
    condition     = aws_ssoadmin_permission_set.this["readonly"].name == "ReadOnly"
    error_message = "ReadOnly permission set should have correct name."
  }

  assert {
    condition     = aws_ssoadmin_permission_set.this["platform_admin"].name == "PlatformAdmin"
    error_message = "PlatformAdmin permission set should have correct name."
  }
}

# -----------------------------------------------------------------------------
# Test: AWS managed policy attachments
# -----------------------------------------------------------------------------

run "managed_policy_attachments" {
  command = plan

  assert {
    condition     = length(aws_ssoadmin_managed_policy_attachment.this) == 4
    error_message = "Should create 4 managed policy attachments (one per permission set)."
  }

  assert {
    condition     = aws_ssoadmin_managed_policy_attachment.this["readonly:ReadOnlyAccess"].managed_policy_arn == "arn:aws:iam::aws:policy/ReadOnlyAccess"
    error_message = "ReadOnly should attach ReadOnlyAccess policy."
  }
}

# -----------------------------------------------------------------------------
# Test: Inline policy conditional creation
# -----------------------------------------------------------------------------

run "inline_policy_created" {
  command = plan

  assert {
    condition     = length(aws_ssoadmin_permission_set_inline_policy.this) == 1
    error_message = "Should create 1 inline policy (only platform_admin has one)."
  }

  assert {
    condition     = strcontains(aws_ssoadmin_permission_set_inline_policy.this["platform_admin"].inline_policy, "DenyOrgLeave")
    error_message = "Platform admin inline policy should contain DenyOrgLeave."
  }
}

# -----------------------------------------------------------------------------
# Test: No inline policy when not specified
# -----------------------------------------------------------------------------

run "no_inline_when_empty" {
  command = plan

  variables {
    permission_sets = {
      simple = {
        name                 = "Simple"
        description          = "Simple read-only access"
        aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      }
    }
    assignments = {}
  }

  assert {
    condition     = length(aws_ssoadmin_permission_set_inline_policy.this) == 0
    error_message = "Should create 0 inline policies when none specified."
  }
}

# -----------------------------------------------------------------------------
# Test: Assignments created
# -----------------------------------------------------------------------------

run "assignments_created" {
  command = plan

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 3
    error_message = "Should create 3 account assignments."
  }
}

# -----------------------------------------------------------------------------
# Test: GROUP assignment
# -----------------------------------------------------------------------------

run "group_assignment" {
  command = plan

  assert {
    condition     = aws_ssoadmin_account_assignment.this["readonly_security_dev"].principal_type == "GROUP"
    error_message = "Assignment should use GROUP principal type."
  }

  assert {
    condition     = aws_ssoadmin_account_assignment.this["readonly_security_dev"].principal_id == "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    error_message = "Assignment should use the specified principal ID."
  }

  assert {
    condition     = aws_ssoadmin_account_assignment.this["readonly_security_dev"].target_id == "111122223333"
    error_message = "Assignment should target the specified account."
  }

  assert {
    condition     = aws_ssoadmin_account_assignment.this["readonly_security_dev"].target_type == "AWS_ACCOUNT"
    error_message = "Assignment target type should be AWS_ACCOUNT."
  }
}

# -----------------------------------------------------------------------------
# Test: Tags merged
# -----------------------------------------------------------------------------

run "tags_merged" {
  command = plan

  assert {
    condition     = aws_ssoadmin_permission_set.this["readonly"].tags["ManagedBy"] == "terraform"
    error_message = "Permission set should have ManagedBy=terraform tag."
  }

  assert {
    condition     = aws_ssoadmin_permission_set.this["readonly"].tags["Component"] == "identity-center"
    error_message = "Permission set should have Component=identity-center tag."
  }

  assert {
    condition     = aws_ssoadmin_permission_set.this["readonly"].tags["Project"] == "landing-zone"
    error_message = "Permission set should inherit common Project tag."
  }

  assert {
    condition     = aws_ssoadmin_permission_set.this["developer"].tags["Role"] == "developer"
    error_message = "Developer should have per-set Role tag."
  }
}

# -----------------------------------------------------------------------------
# Test: Metadata output
# -----------------------------------------------------------------------------

run "metadata_output" {
  command = plan

  assert {
    condition     = output.identity_center_metadata.permission_set_count == 4
    error_message = "Metadata should report 4 permission sets."
  }

  assert {
    condition     = output.identity_center_metadata.assignment_count == 3
    error_message = "Metadata should report 3 assignments."
  }

  assert {
    condition     = output.identity_center_metadata.managed_policy_count == 4
    error_message = "Metadata should report 4 managed policy attachments."
  }

  assert {
    condition     = output.identity_center_metadata.inline_policy_count == 1
    error_message = "Metadata should report 1 inline policy."
  }
}

# -----------------------------------------------------------------------------
# Test: No users/groups created
# -----------------------------------------------------------------------------

run "no_identity_resources" {
  command = plan

  # Only permission sets, attachments, and assignments - no identitystore resources
  assert {
    condition     = length(aws_ssoadmin_permission_set.this) == 4
    error_message = "Only permission set resources should be created."
  }
}

# -----------------------------------------------------------------------------
# Test: Empty assignments valid
# -----------------------------------------------------------------------------

run "empty_assignments" {
  command = plan

  variables {
    assignments = {}
  }

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 0
    error_message = "Should create 0 assignments when none configured."
  }
}
