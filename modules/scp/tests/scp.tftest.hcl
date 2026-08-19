# -----------------------------------------------------------------------------
# SCP Module - Terraform Native Tests (Mocked Provider)
#
# Validates SCP module logic without AWS API calls.
# Run with: terraform -chdir=modules/scp test
# No AWS credentials required.
# -----------------------------------------------------------------------------

mock_provider "aws" {}

# -----------------------------------------------------------------------------
# Variables shared across test runs
# -----------------------------------------------------------------------------

variables {
  approved_regions = ["us-east-1", "us-west-2"]

  target_ids = {
    "ROOT"              = "r-synth"
    "Security"          = "ou-synth-security"
    "Infrastructure"    = "ou-synth-infra"
    "Workloads/NonProd" = "ou-synth-nonprod"
    "Workloads/Prod"    = "ou-synth-prod"
    "Sandbox"           = "ou-synth-sandbox"
    "Suspended"         = "ou-synth-suspended"
  }

  policies = {
    deny_root_user = {
      name        = "deny-root-user"
      description = "Deny all actions by root user in member accounts"
      content     = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"DenyRootUserActions\",\"Effect\":\"Deny\",\"Action\":\"*\",\"Resource\":\"*\",\"Condition\":{\"StringLike\":{\"aws:PrincipalArn\":\"arn:aws:iam::*:root\"}}}]}"
      targets     = ["Security", "Infrastructure", "Workloads/NonProd", "Workloads/Prod", "Sandbox"]
      tags        = { Scope = "baseline" }
    }
    deny_unapproved_regions = {
      name        = "deny-unapproved-regions"
      description = "Restrict operations to approved AWS regions only"
      content     = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"DenyUnapprovedRegions\",\"Effect\":\"Deny\",\"NotAction\":[\"iam:*\",\"organizations:*\",\"route53:*\",\"sts:*\"],\"Resource\":\"*\",\"Condition\":{\"StringNotEquals\":{\"aws:RequestedRegion\":[\"us-east-1\",\"us-west-2\"]}}}]}"
      targets     = ["Workloads/NonProd", "Workloads/Prod", "Sandbox"]
    }
    require_imdsv2 = {
      name        = "require-imdsv2"
      description = "Require IMDSv2 for all EC2 instance launches"
      content     = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"DenyIMDSv1LaunchOnly\",\"Effect\":\"Deny\",\"Action\":\"ec2:RunInstances\",\"Resource\":\"arn:aws:ec2:*:*:instance/*\",\"Condition\":{\"StringNotEquals\":{\"ec2:MetadataHttpTokens\":\"required\"}}}]}"
      targets     = ["Workloads/NonProd", "Workloads/Prod"]
    }
  }
}

# -----------------------------------------------------------------------------
# Test: Correct number of policies created
# -----------------------------------------------------------------------------

run "policies_created" {
  command = plan

  assert {
    condition     = length(aws_organizations_policy.this) == 3
    error_message = "Should create 3 SCP policies."
  }
}

# -----------------------------------------------------------------------------
# Test: Policy type is SERVICE_CONTROL_POLICY
# -----------------------------------------------------------------------------

run "policy_type_is_scp" {
  command = plan

  assert {
    condition     = aws_organizations_policy.this["deny_root_user"].type == "SERVICE_CONTROL_POLICY"
    error_message = "Policy type should be SERVICE_CONTROL_POLICY."
  }

  assert {
    condition     = aws_organizations_policy.this["deny_unapproved_regions"].type == "SERVICE_CONTROL_POLICY"
    error_message = "Region deny policy type should be SERVICE_CONTROL_POLICY."
  }

  assert {
    condition     = aws_organizations_policy.this["require_imdsv2"].type == "SERVICE_CONTROL_POLICY"
    error_message = "IMDSv2 policy type should be SERVICE_CONTROL_POLICY."
  }
}

# -----------------------------------------------------------------------------
# Test: Correct policy names
# -----------------------------------------------------------------------------

run "policy_names_correct" {
  command = plan

  assert {
    condition     = aws_organizations_policy.this["deny_root_user"].name == "deny-root-user"
    error_message = "Root user policy should have name 'deny-root-user'."
  }

  assert {
    condition     = aws_organizations_policy.this["deny_unapproved_regions"].name == "deny-unapproved-regions"
    error_message = "Region deny policy should have name 'deny-unapproved-regions'."
  }

  assert {
    condition     = aws_organizations_policy.this["require_imdsv2"].name == "require-imdsv2"
    error_message = "IMDSv2 policy should have name 'require-imdsv2'."
  }
}

# -----------------------------------------------------------------------------
# Test: Correct number of attachments
# -----------------------------------------------------------------------------

run "attachments_created" {
  command = plan

  # deny_root_user: 5 targets + deny_unapproved_regions: 3 targets + require_imdsv2: 2 targets = 10
  assert {
    condition     = length(aws_organizations_policy_attachment.this) == 10
    error_message = "Should create 10 policy attachments (5 + 3 + 2)."
  }
}

# -----------------------------------------------------------------------------
# Test: Attachment target resolution
# -----------------------------------------------------------------------------

run "attachment_targets_resolved" {
  command = plan

  assert {
    condition     = aws_organizations_policy_attachment.this["deny_root_user:Security"].target_id == "ou-synth-security"
    error_message = "Security target should resolve to ou-synth-security."
  }

  assert {
    condition     = aws_organizations_policy_attachment.this["deny_unapproved_regions:Workloads/Prod"].target_id == "ou-synth-prod"
    error_message = "Workloads/Prod target should resolve to ou-synth-prod."
  }

  assert {
    condition     = aws_organizations_policy_attachment.this["require_imdsv2:Workloads/NonProd"].target_id == "ou-synth-nonprod"
    error_message = "Workloads/NonProd target should resolve to ou-synth-nonprod."
  }
}

# -----------------------------------------------------------------------------
# Test: No implicit root attachment
# -----------------------------------------------------------------------------

run "no_implicit_root_attachment" {
  command = plan

  # None of the test policies target ROOT
  assert {
    condition = alltrue([
      for key, attachment in aws_organizations_policy_attachment.this :
      attachment.target_id != "r-synth"
    ])
    error_message = "No policy should be implicitly attached to ROOT."
  }
}

# -----------------------------------------------------------------------------
# Test: Module-generated tags
# -----------------------------------------------------------------------------

run "policy_tags_include_managed_by" {
  command = plan

  assert {
    condition     = aws_organizations_policy.this["deny_root_user"].tags["ManagedBy"] == "terraform"
    error_message = "Policy should have ManagedBy=terraform tag."
  }

  assert {
    condition     = aws_organizations_policy.this["deny_root_user"].tags["PolicyKey"] == "deny_root_user"
    error_message = "Policy should have PolicyKey tag matching the map key."
  }
}

# -----------------------------------------------------------------------------
# Test: User tags preserved
# -----------------------------------------------------------------------------

run "user_tags_preserved" {
  command = plan

  assert {
    condition     = aws_organizations_policy.this["deny_root_user"].tags["Scope"] == "baseline"
    error_message = "User-provided Scope tag should be preserved."
  }
}

# -----------------------------------------------------------------------------
# Test: Region deny policy content generated
# -----------------------------------------------------------------------------

run "region_deny_content_generated" {
  command = plan

  assert {
    condition     = length(output.region_deny_policy_content) > 0
    error_message = "Region deny policy content should be generated when approved_regions is set."
  }

  assert {
    condition     = can(jsondecode(output.region_deny_policy_content))
    error_message = "Region deny policy content should be valid JSON."
  }
}

# -----------------------------------------------------------------------------
# Test: Region deny contains approved regions
# -----------------------------------------------------------------------------

run "region_deny_contains_approved_regions" {
  command = plan

  assert {
    condition     = strcontains(output.region_deny_policy_content, "us-east-1")
    error_message = "Region deny policy should contain us-east-1."
  }

  assert {
    condition     = strcontains(output.region_deny_policy_content, "us-west-2")
    error_message = "Region deny policy should contain us-west-2."
  }
}

# -----------------------------------------------------------------------------
# Test: Region deny contains DenyUnapprovedRegions statement
# -----------------------------------------------------------------------------

run "region_deny_structure" {
  command = plan

  assert {
    condition     = strcontains(output.region_deny_policy_content, "DenyUnapprovedRegions")
    error_message = "Region deny policy should contain DenyUnapprovedRegions Sid."
  }

  assert {
    condition     = strcontains(output.region_deny_policy_content, "NotAction")
    error_message = "Region deny policy should use NotAction for global service exclusions."
  }
}

# -----------------------------------------------------------------------------
# Test: Root user policy contains expected condition
# -----------------------------------------------------------------------------

run "root_user_policy_condition" {
  command = plan

  assert {
    condition     = strcontains(aws_organizations_policy.this["deny_root_user"].content, "aws:PrincipalArn")
    error_message = "Root user policy should contain aws:PrincipalArn condition."
  }

  assert {
    condition     = strcontains(aws_organizations_policy.this["deny_root_user"].content, "arn:aws:iam::*:root")
    error_message = "Root user policy should reference the root user ARN pattern."
  }
}

# -----------------------------------------------------------------------------
# Test: IMDSv2 policy contains expected condition
# -----------------------------------------------------------------------------

run "imdsv2_policy_condition" {
  command = plan

  assert {
    condition     = strcontains(aws_organizations_policy.this["require_imdsv2"].content, "ec2:MetadataHttpTokens")
    error_message = "IMDSv2 policy should contain ec2:MetadataHttpTokens condition."
  }

  assert {
    condition     = strcontains(aws_organizations_policy.this["require_imdsv2"].content, "ec2:RunInstances")
    error_message = "IMDSv2 policy should reference ec2:RunInstances action."
  }
}

# -----------------------------------------------------------------------------
# Test: Policy metadata output
# -----------------------------------------------------------------------------

run "policy_metadata_correct" {
  command = plan

  assert {
    condition     = output.policy_metadata.policy_count == 3
    error_message = "Policy metadata should report 3 policies."
  }

  assert {
    condition     = output.policy_metadata.attachment_count == 10
    error_message = "Policy metadata should report 10 attachments."
  }
}

# -----------------------------------------------------------------------------
# Test: Empty approved_regions produces empty content
# -----------------------------------------------------------------------------

run "empty_regions_no_content" {
  command = plan

  variables {
    approved_regions = []
  }

  assert {
    condition     = output.region_deny_policy_content == ""
    error_message = "Region deny content should be empty when no approved regions specified."
  }
}
