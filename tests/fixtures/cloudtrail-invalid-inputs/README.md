# CloudTrail Invalid Inputs Test Fixtures

| File | Validation Tested |
|------|-------------------|
| `invalid-trail-name.tfvars` | Trail name must start with a letter |
| `invalid-bucket-name.tfvars` | S3 bucket name must be valid format |
| `invalid-event-type.tfvars` | Event type must be All/ReadOnly/WriteOnly |
| `invalid-tag-prefix.tfvars` | Tag keys must not use aws: prefix |
