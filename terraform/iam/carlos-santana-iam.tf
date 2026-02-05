# =============================================================================
# IAM User with Okta Group Mapping
# Carlos Santana - Red Security Team
# =============================================================================

# IAM Group (maps to Okta group: Red Security Team)
resource "aws_iam_group" "red_security_team" {
  name = "red-security-team"
  path = "/users/"
}

# IAM Group Policy - PowerUser Access for Red Team activities
resource "aws_iam_group_policy_attachment" "red_security_team_policy" {
  group      = aws_iam_group.red_security_team.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# IAM User
resource "aws_iam_user" "carlos_santana" {
  name = "carlos.santana"
  path = "/users/"
  
  tags = {
    OktaGroup   = "Red Security Team"
    Email       = "carlos.santana@demoaactivec.com"
    Team        = "Red Security"
    ManagedBy   = "terraform"
    Description = "User synced from Okta"
  }
}

# Add user to group
resource "aws_iam_user_group_membership" "carlos_santana_membership" {
  user   = aws_iam_user.carlos_santana.name
  groups = [aws_iam_group.red_security_team.name]
}