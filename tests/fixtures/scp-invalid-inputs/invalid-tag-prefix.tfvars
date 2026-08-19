# Invalid: tag key uses reserved "aws:" prefix
# Expected error: "Tag keys must not use the reserved 'aws:' prefix."

policies = {
  bad = {
    name        = "test-policy"
    description = "Bad tag"
    content     = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    targets     = ["Security"]
    tags        = { "aws:reserved" = "bad" }
  }
}
