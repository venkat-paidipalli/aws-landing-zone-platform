# Invalid: policy name is empty
# Expected error: "Policy names must be between 1 and 128 characters."

policies = {
  bad = {
    name        = ""
    description = "Empty name"
    content     = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    targets     = ["Security"]
  }
}
