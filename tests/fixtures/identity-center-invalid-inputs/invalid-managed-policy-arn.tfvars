# Invalid: managed policy ARN doesn't start with arn:aws:iam::aws:policy/
# Expected error: "AWS managed policy ARNs must start with 'arn:aws:iam::aws:policy/'."

permission_sets = {
  bad = {
    name                 = "Bad"
    description          = "Invalid policy ARN"
    aws_managed_policies = ["not-a-valid-policy-arn"]
  }
}
