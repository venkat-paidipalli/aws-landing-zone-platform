# SCP Invalid Inputs Test Fixtures

This directory contains `.tfvars` files that document known validation failure
cases for the SCP module. Each file targets a specific validation rule.

## How to Test Validation Failures

```bash
terraform -chdir=tests/fixtures/scp-invalid-inputs plan \
  -var-file=invalid-empty-name.tfvars
```

Expected result: Terraform should reject the input with a clear error message.

## Failure Cases Documented

| File | Validation Tested |
|------|-------------------|
| `invalid-empty-name.tfvars` | Policy name must be 1-128 characters |
| `invalid-unknown-target.tfvars` | Targets must exist in target_ids map |
| `invalid-empty-content.tfvars` | Policy content must not be empty |
| `invalid-region-format.tfvars` | Approved regions must be valid format |
| `invalid-tag-prefix.tfvars` | Tag keys must not use aws: prefix |
