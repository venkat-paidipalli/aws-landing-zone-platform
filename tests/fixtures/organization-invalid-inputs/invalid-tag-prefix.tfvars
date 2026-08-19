# Invalid: tag key uses reserved "aws:" prefix
# Expected error: "Tag keys must not use the reserved 'aws:' prefix."

organizational_units = {
  Security = {
    parent = "ROOT"
    tags = {
      "aws:reserved-key" = "this-should-fail"
    }
  }
}

accounts = {}
