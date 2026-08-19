# Organization Invalid Inputs Test Fixtures

This directory contains `.tfvars` files that document known validation failure
cases for the organization module. Each file targets a specific validation rule.

## How to Test Validation Failures

These fixtures are NOT run as part of the standard `validate` pipeline because
they are designed to fail. To manually verify a validation works:

```bash
terraform -chdir=tests/fixtures/organization-invalid-inputs plan \
  -var-file=invalid-feature-set.tfvars
```

Expected result: Terraform should reject the input with a clear error message.

## Failure Cases Documented

| File | Validation Tested |
|------|-------------------|
| `invalid-feature-set.tfvars` | Feature set must be ALL or CONSOLIDATED_BILLING |
| `invalid-org-name.tfvars` | Organization name must be lowercase slug format |
| `invalid-ou-path.tfvars` | OU paths must not have leading/trailing slashes |
| `invalid-email.tfvars` | Account emails must be syntactically valid |
| `invalid-tag-prefix.tfvars` | Tag keys must not use aws: reserved prefix |
| `invalid-role-name.tfvars` | Role names must match IAM naming rules |
