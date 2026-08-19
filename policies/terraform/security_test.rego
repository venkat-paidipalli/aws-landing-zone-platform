# -----------------------------------------------------------------------------
# Security Policy Tests
# Run with: conftest verify --policy policies/terraform/
# -----------------------------------------------------------------------------
package terraform.security

# Test: public subnet without justification is denied
test_public_subnet_denied {
  input := {"resource_changes": [{
    "type": "aws_subnet",
    "address": "module.vpc.aws_subnet.public",
    "change": {"after": {
      "map_public_ip_on_launch": true,
      "tags": {}
    }}
  }]}
  count(deny) > 0
}

# Test: private subnet is allowed
test_private_subnet_allowed {
  input := {"resource_changes": [{
    "type": "aws_subnet",
    "address": "module.vpc.aws_subnet.private",
    "change": {"after": {
      "map_public_ip_on_launch": false,
      "tags": {"ManagedBy": "terraform"}
    }}
  }]}
  count(deny) == 0
}

# Test: public subnet with justification is allowed
test_public_subnet_with_justification_allowed {
  input := {"resource_changes": [{
    "type": "aws_subnet",
    "address": "module.vpc.aws_subnet.public",
    "change": {"after": {
      "map_public_ip_on_launch": true,
      "tags": {"PublicJustification": "NAT gateway subnet"}
    }}
  }]}
  # Should not trigger the public subnet deny
  not deny["Subnet module.vpc.aws_subnet.public has map_public_ip_on_launch=true without PublicJustification tag."]
}
