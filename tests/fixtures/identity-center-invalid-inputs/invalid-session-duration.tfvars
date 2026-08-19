# Invalid: session duration not ISO-8601
# Expected error: "Session duration must be ISO-8601 format..."

permission_sets = {
  bad = {
    name             = "Bad"
    description      = "Invalid session"
    session_duration = "2hours"
  }
}
