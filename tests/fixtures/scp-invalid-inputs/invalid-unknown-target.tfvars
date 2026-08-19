# Invalid: target path does not exist in target_ids
# Expected error: "All policy targets must exist in the target_ids map."

policies = {
  bad = {
    name        = "test-policy"
    description = "Unknown target"
    content     = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    targets     = ["NonExistentOU"]
  }
}
