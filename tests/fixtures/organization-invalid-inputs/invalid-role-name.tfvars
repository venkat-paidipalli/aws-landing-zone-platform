# Invalid: role name contains spaces and special characters
# Expected error: "Role names must be valid IAM role names..."

organizational_units = {
  Security = {
    parent = "ROOT"
  }
}

accounts = {
  bad_role = {
    name      = "lz-bad-role"
    email     = "aws+bad-role@example.invalid"
    ou_path   = "Security"
    role_name = "invalid role name!!"
  }
}
