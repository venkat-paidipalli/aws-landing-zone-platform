# -----------------------------------------------------------------------------
# Config Module - Main
#
# Creates an AWS Config governance baseline:
# - Configuration recorder (what to record)
# - Delivery channel (where to send data)
# - Recorder status (enable recording)
# - Managed Config rules (detective compliance checks)
#
# This module is DETECTIVE only. It evaluates compliance but does NOT
# remediate non-compliant resources. Remediation is a future concern.
#
# Dependencies:
# - IAM role must exist before this module runs (caller provides ARN)
# - S3 bucket must exist before this module runs (caller provides name)
# - Optional SNS topic must exist if specified
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration Recorder
# -----------------------------------------------------------------------------

resource "aws_config_configuration_recorder" "this" {
  name     = var.recorder_name
  role_arn = var.recorder_role_arn

  recording_group {
    all_supported                 = var.recording_all_resources
    include_global_resource_types = var.include_global_resource_types

    resource_types = var.recording_all_resources ? [] : var.selected_resource_types
  }
}

# -----------------------------------------------------------------------------
# Delivery Channel
#
# Must be created before the recorder can be enabled.
# Delivers configuration snapshots and change notifications to S3.
# -----------------------------------------------------------------------------

resource "aws_config_delivery_channel" "this" {
  name           = var.delivery_channel_name
  s3_bucket_name = var.delivery_s3_bucket
  s3_key_prefix  = var.delivery_s3_key_prefix != "" ? var.delivery_s3_key_prefix : null
  sns_topic_arn  = var.delivery_sns_topic_arn != "" ? var.delivery_sns_topic_arn : null

  snapshot_delivery_properties {
    delivery_frequency = var.snapshot_delivery_frequency
  }

  depends_on = [aws_config_configuration_recorder.this]
}

# -----------------------------------------------------------------------------
# Recorder Status (Enable Recording)
#
# Ordering guarantee:
# 1. Recorder created (defines what to record)
# 2. Delivery channel created (defines where to send data)
# 3. Recorder enabled (starts recording)
#
# The depends_on on the delivery channel ensures correct ordering.
# AWS requires a delivery channel before recording can be enabled.
# -----------------------------------------------------------------------------

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

# -----------------------------------------------------------------------------
# Managed Config Rules
#
# These are AWS-managed rules that evaluate resource compliance.
# They are detective only — no automatic remediation.
#
# Rules depend on the recorder being enabled to function.
# -----------------------------------------------------------------------------

resource "aws_config_config_rule" "managed" {
  for_each = var.managed_rules

  name        = each.value.name
  description = each.value.description

  source {
    owner             = "AWS"
    source_identifier = each.value.source_identifier
  }

  input_parameters = length(each.value.input_parameters) > 0 ? jsonencode(each.value.input_parameters) : null

  maximum_execution_frequency = each.value.maximum_execution_frequency != "" ? each.value.maximum_execution_frequency : null

  tags = merge(
    var.tags,
    each.value.tags,
    {
      ManagedBy = "terraform"
      Component = "aws-config"
      RuleKey   = each.key
    },
  )

  depends_on = [aws_config_configuration_recorder_status.this]
}
