# -----------------------------------------------------------------------------
# Config Interface Test Fixture
#
# Demonstrates a realistic fictional Config baseline configuration.
# All identifiers are synthetic/fictional — no real AWS accounts.
#
# No AWS credentials required (uses provider with skip flags).
# -----------------------------------------------------------------------------

terraform {
  required_version = "~> 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  access_key = "mock-access-key-for-validation"
  secret_key = "mock-secret-key-for-validation"
}

# -----------------------------------------------------------------------------
# Config Module Instance
#
# NOTE: All ARNs and bucket names below are FICTIONAL.
# Account ID 555500001111 is a synthetic documentation placeholder.
# -----------------------------------------------------------------------------

module "config" {
  source = "../../../modules/config"

  recorder_name     = "lz-config-recorder"
  recorder_role_arn = "arn:aws:iam::555500001111:role/aws-config-recorder-role"

  recording_all_resources       = true
  include_global_resource_types = true

  delivery_channel_name       = "lz-config-channel"
  delivery_s3_bucket          = "lz-config-delivery-555500001111"
  delivery_s3_key_prefix      = "config"
  snapshot_delivery_frequency = "Six_Hours"

  tags = {
    Environment = "production"
    Project     = "landing-zone"
    Owner       = "platform-team"
  }

  managed_rules = {
    s3_public_read = {
      name              = "s3-bucket-public-read-prohibited"
      source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
      description       = "Checks that S3 buckets do not allow public read access"
    }
    encrypted_volumes = {
      name              = "encrypted-volumes"
      source_identifier = "ENCRYPTED_VOLUMES"
      description       = "Checks whether attached EBS volumes are encrypted"
    }
    root_mfa = {
      name                        = "root-account-mfa-enabled"
      source_identifier           = "ROOT_ACCOUNT_MFA_ENABLED"
      description                 = "Checks whether root account has MFA enabled"
      maximum_execution_frequency = "TwentyFour_Hours"
    }
    iam_password_policy = {
      name              = "iam-password-policy"
      source_identifier = "IAM_PASSWORD_POLICY"
      description       = "Checks IAM password policy meets requirements"
      input_parameters = {
        RequireUppercaseCharacters = "true"
        RequireLowercaseCharacters = "true"
        RequireNumbers             = "true"
        RequireSymbols             = "true"
        MinimumPasswordLength      = "14"
      }
    }
    cloudtrail_enabled = {
      name                        = "cloudtrail-enabled"
      source_identifier           = "CLOUD_TRAIL_ENABLED"
      description                 = "Checks whether CloudTrail is enabled in the account"
      maximum_execution_frequency = "TwentyFour_Hours"
    }
    ec2_managed_by_ssm = {
      name              = "ec2-instance-managed-by-ssm"
      source_identifier = "EC2_INSTANCE_MANAGED_BY_SSM"
      description       = "Checks whether EC2 instances are managed by Systems Manager"
    }
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "recorder_name" {
  value = module.config.recorder_name
}

output "delivery_channel_name" {
  value = module.config.delivery_channel_name
}

output "rule_names" {
  value = module.config.config_rule_names
}

output "metadata" {
  value = module.config.config_metadata
}
