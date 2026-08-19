# Config Invalid Inputs Test Fixtures

This directory contains `.tfvars` files that document known validation failure
cases for the Config module. Each file targets a specific validation rule.

## How to Test Validation Failures

```bash
terraform -chdir=tests/fixtures/config-invalid-inputs plan \
  -var-file=invalid-role-arn.tfvars
```

Expected result: Terraform should reject the input with a clear error message.

## Failure Cases Documented

| File | Validation Tested |
|------|-------------------|
| `invalid-recorder-name.tfvars` | Recorder name must start with a letter |
| `invalid-role-arn.tfvars` | Role ARN must be valid IAM role format |
| `invalid-bucket-name.tfvars` | S3 bucket name must be valid format |
| `invalid-snapshot-frequency.tfvars` | Frequency must be an allowed value |
| `invalid-rule-name.tfvars` | Rule name must be 1-128 characters |
| `invalid-source-identifier.tfvars` | Source identifier must be uppercase |
| `invalid-tag-prefix.tfvars` | Tag keys must not use aws: prefix |
