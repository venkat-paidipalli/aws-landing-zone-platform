# Invalid: tag key uses reserved "aws:" prefix
# Expected error: "Tag keys must not use the reserved 'aws:' prefix."

tags = {
  "aws:reserved" = "bad"
}
