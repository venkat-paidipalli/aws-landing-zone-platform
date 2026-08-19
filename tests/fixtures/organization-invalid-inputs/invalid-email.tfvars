# Invalid: email missing @ symbol
# Expected error: "Account emails must be syntactically valid..."

organizational_units = {
  Security = {
    parent = "ROOT"
  }
}

accounts = {
  bad_email = {
    name    = "lz-bad-email"
    email   = "not-an-email-address"
    ou_path = "Security"
  }
}
