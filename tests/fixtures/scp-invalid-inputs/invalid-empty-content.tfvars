# Invalid: policy content is empty
# Expected error: "Policy content must not be empty."

policies = {
  bad = {
    name        = "test-policy"
    description = "Empty content"
    content     = ""
    targets     = ["Security"]
  }
}
