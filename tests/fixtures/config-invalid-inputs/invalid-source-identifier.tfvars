# Invalid: source identifier contains lowercase
# Expected error: "Source identifiers must be uppercase with underscores..."

managed_rules = {
  bad_rule = {
    name              = "bad-rule"
    source_identifier = "invalid_lowercase_identifier"
    description       = "Bad source ID"
  }
}
