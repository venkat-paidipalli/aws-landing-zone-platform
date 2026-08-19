# Invalid: standard ARN does not start with arn:aws:securityhub:
# Expected error: "Each standard ARN must begin with 'arn:aws:securityhub:'."

standards = {
  bad_standard = {
    arn = "not-a-valid-arn"
  }
}
