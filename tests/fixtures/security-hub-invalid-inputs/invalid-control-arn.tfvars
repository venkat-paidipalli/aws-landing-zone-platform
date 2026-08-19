# Invalid: disabled_controls standards_arn does not start with arn:aws:securityhub:
# Expected error: "Each standards_arn in disabled_controls must begin with 'arn:aws:securityhub:'."

disabled_controls = {
  bad_control = {
    standards_arn = "invalid-arn-format"
    control_id    = "S3.1"
    reason        = "Testing"
  }
}
