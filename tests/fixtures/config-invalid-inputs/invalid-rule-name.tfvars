# Invalid: rule name is empty
# Expected error: "Rule names must be between 1 and 128 characters."

managed_rules = {
  bad_rule = {
    name              = ""
    source_identifier = "ENCRYPTED_VOLUMES"
    description       = "Empty name"
  }
}
