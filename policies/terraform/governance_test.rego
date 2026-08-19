# -----------------------------------------------------------------------------
# Governance Policy Tests
# Run with: conftest verify --policy policies/terraform/
# -----------------------------------------------------------------------------
package terraform.governance

# Test: Control Tower resources are denied
test_control_tower_denied {
  input := {"resource_changes": [{
    "type": "aws_controltower_control",
    "address": "aws_controltower_control.example",
    "change": {"after": {}}
  }]}
  count(deny) > 0
}

# Test: Organization trail is denied
test_organization_trail_denied {
  input := {"resource_changes": [{
    "type": "aws_cloudtrail",
    "address": "module.cloudtrail.aws_cloudtrail.this",
    "change": {"after": {
      "is_organization_trail": true,
      "tags": {"ManagedBy": "terraform"}
    }}
  }]}
  count(deny) > 0
}

# Test: Account-level trail is allowed
test_account_trail_allowed {
  input := {"resource_changes": [{
    "type": "aws_cloudtrail",
    "address": "module.cloudtrail.aws_cloudtrail.this",
    "change": {"after": {
      "is_organization_trail": false,
      "tags": {"ManagedBy": "terraform"}
    }}
  }]}
  count(deny) == 0
}

# Test: Normal VPC is allowed
test_vpc_allowed {
  input := {"resource_changes": [{
    "type": "aws_vpc",
    "address": "module.vpc.aws_vpc.this",
    "change": {"after": {
      "tags": {"ManagedBy": "terraform"}
    }}
  }]}
  count(deny) == 0
}

# Test: Missing ManagedBy tag produces warning
test_missing_managed_by_warns {
  input := {"resource_changes": [{
    "type": "aws_s3_bucket",
    "address": "aws_s3_bucket.example",
    "change": {"after": {
      "tags": {"Environment": "dev"}
    }}
  }]}
  count(warn) > 0
}
