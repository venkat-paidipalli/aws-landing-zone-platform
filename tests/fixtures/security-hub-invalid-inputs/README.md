# Security Hub Invalid Inputs Test Fixtures

This directory contains `.tfvars` files that document known validation failure
cases for the Security Hub module.

## How to Test Validation Failures

```bash
terraform -chdir=tests/fixtures/security-hub-invalid-inputs plan \
  -var-file=invalid-standards-arn.tfvars
```

Expected result: Terraform should reject the input with a clear error message.

## Failure Cases Documented

| File | Validation Tested |
|------|-------------------|
| `invalid-standards-arn.tfvars` | Standards ARN must begin with arn:aws:securityhub: |
| `invalid-control-arn.tfvars` | Control standards_arn must be valid |
| `invalid-tag-prefix.tfvars` | Tag keys must not use aws: prefix |
