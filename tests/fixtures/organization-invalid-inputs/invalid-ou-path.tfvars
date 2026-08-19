# Invalid: OU path has leading slash
# Expected error: "OU paths must not start or end with '/'."

organizational_units = {
  "/BadPath" = {
    parent      = "ROOT"
    description = "This path has a leading slash"
  }
}

accounts = {}
