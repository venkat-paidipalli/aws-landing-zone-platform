# -----------------------------------------------------------------------------
# Config Module - Outputs
# -----------------------------------------------------------------------------

output "recorder_name" {
  description = "Name of the AWS Config configuration recorder."
  value       = aws_config_configuration_recorder.this.name
}

output "delivery_channel_name" {
  description = "Name of the AWS Config delivery channel."
  value       = aws_config_delivery_channel.this.name
}

output "config_rule_ids" {
  description = "Map of rule logical key to AWS Config rule ID."
  value = {
    for key, rule in aws_config_config_rule.managed : key => rule.id
  }
}

output "config_rule_arns" {
  description = "Map of rule logical key to AWS Config rule ARN."
  value = {
    for key, rule in aws_config_config_rule.managed : key => rule.arn
  }
}

output "config_rule_names" {
  description = "Map of rule logical key to AWS Config rule name."
  value = {
    for key, rule in aws_config_config_rule.managed : key => rule.name
  }
}

output "config_metadata" {
  description = "Summary metadata about the Config baseline configuration."
  value = {
    recorder_name      = var.recorder_name
    delivery_bucket    = var.delivery_s3_bucket
    snapshot_frequency = var.snapshot_delivery_frequency
    recording_all      = var.recording_all_resources
    include_global     = var.include_global_resource_types
    rule_count         = length(var.managed_rules)
    sns_enabled        = var.delivery_sns_topic_arn != ""
  }
}
