# Invalid: principal type not GROUP or USER
# Expected error: "Principal type must be 'GROUP' or 'USER'."

permission_sets = {
  test = {
    name        = "Test"
    description = "Valid"
  }
}

assignments = {
  bad = {
    permission_set_key = "test"
    principal_id       = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    principal_type     = "ROLE"
    target_account_id  = "111122223333"
  }
}
