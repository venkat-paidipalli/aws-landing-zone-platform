# Terraform OPA/Rego Policies

## Purpose

Lightweight policy-as-code layer enforcing landing zone governance rules
against Terraform plan output.

## Policies

| File | Package | Description |
|------|---------|-------------|
| `security.rego` | `terraform.security` | Security invariants (public access, keys, encryption) |
| `governance.rego` | `terraform.governance` | Governance rules (CT boundary, org trail, tagging) |

## Rules

### Security (deny)

- No hard-coded AWS access keys (non-mock)
- No public subnets without PublicJustification tag
- No unrestricted security group ingress (0.0.0.0/0 all ports)
- No S3 buckets without encryption

### Governance (deny)

- No `aws_controltower_*` deployment resources
- No organization trails without explicit approval

### Governance (warn)

- Missing ManagedBy tag on trackable resources

## Usage

```bash
# Against a Terraform plan JSON
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan > plan.json
conftest test --policy policies/terraform/ plan.json

# Run policy tests
conftest verify --policy policies/terraform/
```

## Testing

Each policy file has a corresponding `*_test.rego` with synthetic
compliant/non-compliant examples.

## Design Principles

- Small, focused rule set (not a comprehensive policy framework)
- Deterministic (no external data)
- No AWS API calls
- Clear error messages
- Tests for every deny rule
