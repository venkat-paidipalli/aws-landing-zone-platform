# -----------------------------------------------------------------------------
# Security Policies for Terraform Configurations
#
# These policies enforce security invariants across the landing zone.
# Run with: conftest test --policy policies/terraform/ <plan.json>
#
# For repository-level structural checks, these validate .tf file patterns.
# -----------------------------------------------------------------------------
package terraform.security

# Deny hard-coded AWS access keys in Terraform files
deny[msg] {
  input.resource_changes[_].change.after.access_key
  not contains(input.resource_changes[_].change.after.access_key, "mock-")
  msg := "Hard-coded AWS access key detected. Use environment variables or IAM roles."
}

# Deny public VPC subnets without explicit justification
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_subnet"
  resource.change.after.map_public_ip_on_launch == true
  not resource.change.after.tags.PublicJustification
  msg := sprintf("Subnet %s has map_public_ip_on_launch=true without PublicJustification tag.", [resource.address])
}

# Deny unrestricted security group ingress (0.0.0.0/0 on all ports)
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_security_group_rule"
  resource.change.after.type == "ingress"
  resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
  resource.change.after.from_port == 0
  resource.change.after.to_port == 65535
  msg := sprintf("Security group rule %s allows unrestricted ingress (0.0.0.0/0 all ports).", [resource.address])
}

# Deny S3 buckets without encryption
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  not has_encryption(resource.change.after)
  msg := sprintf("S3 bucket %s does not have server-side encryption configured.", [resource.address])
}

has_encryption(bucket) {
  bucket.server_side_encryption_configuration
}

has_encryption(_) = true
