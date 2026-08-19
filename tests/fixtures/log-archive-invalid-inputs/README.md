# Log Archive Invalid Inputs Test Fixtures

| File | Validation Tested |
|------|-------------------|
| `invalid-bucket-name.tfvars` | Bucket name must be valid S3 format |
| `invalid-encryption.tfvars` | Encryption must be AES256 or aws:kms |
| `invalid-tag-prefix.tfvars` | Tag keys must not use aws: prefix |
