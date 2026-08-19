# Identity Center Invalid Inputs Test Fixtures

| File | Validation Tested |
|------|-------------------|
| `invalid-instance-arn.tfvars` | Instance ARN must be valid SSO format |
| `invalid-session-duration.tfvars` | Session duration must be ISO-8601 |
| `invalid-managed-policy-arn.tfvars` | Managed policy ARN must be valid |
| `invalid-principal-type.tfvars` | Principal type must be GROUP or USER |
| `invalid-tag-prefix.tfvars` | Tag keys must not use aws: prefix |
