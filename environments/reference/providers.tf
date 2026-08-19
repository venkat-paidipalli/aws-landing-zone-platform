# -----------------------------------------------------------------------------
# Provider Configuration - Reference Environment
#
# This reference environment uses mock/skip credentials for structural
# validation only. It does NOT connect to AWS.
#
# In a real deployment, providers would use assume-role configurations
# targeting each account:
#
#   provider "aws" {
#     alias  = "security"
#     region = "us-east-1"
#     assume_role {
#       role_arn = "arn:aws:iam::<security-account-id>:role/TerraformExecution"
#     }
#   }
#
# That pattern is documented but not implemented here because it requires
# real AWS credentials.
# -----------------------------------------------------------------------------

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  access_key = "mock-access-key-for-validation"
  secret_key = "mock-secret-key-for-validation"
}
