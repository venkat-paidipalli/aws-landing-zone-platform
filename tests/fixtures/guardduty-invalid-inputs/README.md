# GuardDuty Invalid Inputs Test Fixtures

This directory contains `.tfvars` files that document known validation failure
cases for the GuardDuty module.

## How to Test Validation Failures

```bash
terraform -chdir=tests/fixtures/guardduty-invalid-inputs plan \
  -var-file=invalid-frequency.tfvars
```

Expected result: Terraform should reject the input with a clear error message.

## Failure Cases Documented

| File | Validation Tested |
|------|-------------------|
| `invalid-frequency.tfvars` | Publishing frequency must be allowed value |
| `invalid-tag-prefix.tfvars` | Tag keys must not use aws: prefix |
