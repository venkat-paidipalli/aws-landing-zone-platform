# -----------------------------------------------------------------------------
# Config Module - Terraform Native Tests (Mocked Provider)
#
# Validates the Config module logic without AWS API calls.
# Run with: terraform -chdir=modules/config test
# No AWS credentials required.
# -----------------------------------------------------------------------------

mock_provider "aws" {}

# -----------------------------------------------------------------------------
# Variables shared across test runs
# -----------------------------------------------------------------------------

variables {
  recorder_name     = "lz-config-recorder"
  recorder_role_arn = "arn:aws:iam::111122223333:role/config-recorder-role"

  recording_all_resources       = true
  include_global_resource_types = true

  delivery_channel_name       = "lz-config-channel"
  delivery_s3_bucket          = "lz-config-delivery-bucket"
  delivery_s3_key_prefix      = "config/logs"
  delivery_sns_topic_arn      = ""
  snapshot_delivery_frequency = "Six_Hours"

  tags = {
    Environment = "production"
    Project     = "landing-zone"
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
        MinimumPasswordLength      = "14"
      }
    }
    cloudtrail_enabled = {
      name                        = "cloudtrail-enabled"
      source_identifier           = "CLOUD_TRAIL_ENABLED"
      description                 = "Checks whether CloudTrail is enabled"
      maximum_execution_frequency = "TwentyFour_Hours"
    }
    ec2_managed_by_ssm = {
      name              = "ec2-instance-managed-by-ssm"
      source_identifier = "EC2_INSTANCE_MANAGED_BY_SSM"
      description       = "Checks whether EC2 instances are managed by SSM"
    }
  }
}

# -----------------------------------------------------------------------------
# Test: Recorder created with correct configuration
# -----------------------------------------------------------------------------

run "recorder_created" {
  command = plan

  assert {
    condition     = aws_config_configuration_recorder.this.name == "lz-config-recorder"
    error_message = "Recorder should have the specified name."
  }

  assert {
    condition     = aws_config_configuration_recorder.this.role_arn == "arn:aws:iam::111122223333:role/config-recorder-role"
    error_message = "Recorder should use the specified IAM role ARN."
  }
}

# -----------------------------------------------------------------------------
# Test: Delivery channel created with correct S3 bucket
# -----------------------------------------------------------------------------

run "delivery_channel_created" {
  command = plan

  assert {
    condition     = aws_config_delivery_channel.this.name == "lz-config-channel"
    error_message = "Delivery channel should have the specified name."
  }

  assert {
    condition     = aws_config_delivery_channel.this.s3_bucket_name == "lz-config-delivery-bucket"
    error_message = "Delivery channel should use the specified S3 bucket."
  }

  assert {
    condition     = aws_config_delivery_channel.this.s3_key_prefix == "config/logs"
    error_message = "Delivery channel should use the specified S3 key prefix."
  }
}

# -----------------------------------------------------------------------------
# Test: Recorder is enabled
# -----------------------------------------------------------------------------

run "recorder_enabled" {
  command = plan

  assert {
    condition     = aws_config_configuration_recorder_status.this.is_enabled == true
    error_message = "Recorder status should be enabled."
  }
}

# -----------------------------------------------------------------------------
# Test: Recording all resources behavior
# -----------------------------------------------------------------------------

run "recording_all_resources" {
  command = plan

  assert {
    condition     = aws_config_configuration_recorder.this.recording_group[0].all_supported == true
    error_message = "Recorder should record all supported resources."
  }

  assert {
    condition     = aws_config_configuration_recorder.this.recording_group[0].include_global_resource_types == true
    error_message = "Recorder should include global resource types."
  }
}

# -----------------------------------------------------------------------------
# Test: Selected resource types mode
# -----------------------------------------------------------------------------

run "selected_resource_types_mode" {
  command = plan

  variables {
    recording_all_resources = false
    selected_resource_types = ["AWS::EC2::Instance", "AWS::S3::Bucket"]
  }

  assert {
    condition     = aws_config_configuration_recorder.this.recording_group[0].all_supported == false
    error_message = "Recorder should not record all resources in selected mode."
  }
}

# -----------------------------------------------------------------------------
# Test: SNS topic not set when empty
# -----------------------------------------------------------------------------

run "sns_not_set_when_empty" {
  command = plan

  assert {
    condition     = aws_config_delivery_channel.this.sns_topic_arn == null
    error_message = "SNS topic should be null when not specified."
  }
}

# -----------------------------------------------------------------------------
# Test: SNS topic set when provided
# -----------------------------------------------------------------------------

run "sns_set_when_provided" {
  command = plan

  variables {
    delivery_sns_topic_arn = "arn:aws:sns:us-east-1:111122223333:config-notifications"
  }

  assert {
    condition     = aws_config_delivery_channel.this.sns_topic_arn == "arn:aws:sns:us-east-1:111122223333:config-notifications"
    error_message = "SNS topic should be set when provided."
  }
}

# -----------------------------------------------------------------------------
# Test: Managed rules created
# -----------------------------------------------------------------------------

run "managed_rules_created" {
  command = plan

  assert {
    condition     = length(aws_config_config_rule.managed) == 6
    error_message = "Should create 6 managed Config rules."
  }
}

# -----------------------------------------------------------------------------
# Test: Rules have correct AWS source owner
# -----------------------------------------------------------------------------

run "rules_have_aws_source_owner" {
  command = plan

  assert {
    condition     = aws_config_config_rule.managed["s3_public_read"].source[0].owner == "AWS"
    error_message = "Config rules should have owner 'AWS'."
  }

  assert {
    condition     = aws_config_config_rule.managed["encrypted_volumes"].source[0].owner == "AWS"
    error_message = "Encrypted volumes rule should have owner 'AWS'."
  }
}

# -----------------------------------------------------------------------------
# Test: Correct source identifiers
# -----------------------------------------------------------------------------

run "correct_source_identifiers" {
  command = plan

  assert {
    condition     = aws_config_config_rule.managed["s3_public_read"].source[0].source_identifier == "S3_BUCKET_PUBLIC_READ_PROHIBITED"
    error_message = "S3 rule should have correct source identifier."
  }

  assert {
    condition     = aws_config_config_rule.managed["root_mfa"].source[0].source_identifier == "ROOT_ACCOUNT_MFA_ENABLED"
    error_message = "Root MFA rule should have correct source identifier."
  }

  assert {
    condition     = aws_config_config_rule.managed["cloudtrail_enabled"].source[0].source_identifier == "CLOUD_TRAIL_ENABLED"
    error_message = "CloudTrail rule should have correct source identifier."
  }
}

# -----------------------------------------------------------------------------
# Test: Input parameters encoded correctly
# -----------------------------------------------------------------------------

run "input_parameters_encoded" {
  command = plan

  assert {
    condition     = aws_config_config_rule.managed["iam_password_policy"].input_parameters != null
    error_message = "IAM password policy rule should have input parameters."
  }

  assert {
    condition     = strcontains(aws_config_config_rule.managed["iam_password_policy"].input_parameters, "MinimumPasswordLength")
    error_message = "Input parameters should contain MinimumPasswordLength."
  }
}

# -----------------------------------------------------------------------------
# Test: Tags merged correctly
# -----------------------------------------------------------------------------

run "tags_merged" {
  command = plan

  assert {
    condition     = aws_config_config_rule.managed["s3_public_read"].tags["ManagedBy"] == "terraform"
    error_message = "Rules should have ManagedBy=terraform tag."
  }

  assert {
    condition     = aws_config_config_rule.managed["s3_public_read"].tags["Component"] == "aws-config"
    error_message = "Rules should have Component=aws-config tag."
  }

  assert {
    condition     = aws_config_config_rule.managed["s3_public_read"].tags["Environment"] == "production"
    error_message = "Rules should inherit common tags."
  }

  assert {
    condition     = aws_config_config_rule.managed["s3_public_read"].tags["RuleKey"] == "s3_public_read"
    error_message = "Rules should have RuleKey tag matching the map key."
  }
}

# -----------------------------------------------------------------------------
# Test: Metadata output correct
# -----------------------------------------------------------------------------

run "metadata_output" {
  command = plan

  assert {
    condition     = output.config_metadata.recorder_name == "lz-config-recorder"
    error_message = "Metadata should report recorder name."
  }

  assert {
    condition     = output.config_metadata.delivery_bucket == "lz-config-delivery-bucket"
    error_message = "Metadata should report delivery bucket."
  }

  assert {
    condition     = output.config_metadata.snapshot_frequency == "Six_Hours"
    error_message = "Metadata should report snapshot frequency."
  }

  assert {
    condition     = output.config_metadata.rule_count == 6
    error_message = "Metadata should report 6 rules."
  }

  assert {
    condition     = output.config_metadata.recording_all == true
    error_message = "Metadata should report recording_all=true."
  }

  assert {
    condition     = output.config_metadata.sns_enabled == false
    error_message = "Metadata should report sns_enabled=false when no topic."
  }
}

# -----------------------------------------------------------------------------
# Test: No rules when empty map
# -----------------------------------------------------------------------------

run "no_rules_when_empty" {
  command = plan

  variables {
    managed_rules = {}
  }

  assert {
    condition     = length(aws_config_config_rule.managed) == 0
    error_message = "Should create 0 rules when managed_rules is empty."
  }

  assert {
    condition     = output.config_metadata.rule_count == 0
    error_message = "Metadata should report 0 rules."
  }
}
