# =============================================================================
# IAM User with Okta Group Mapping
# =============================================================================

# IAM Group (maps to Okta group: Security Engineers)
resource "aws_iam_group" "security_engineers" {
  name = "security-engineers"
  path = "/users/"
}

# IAM Group Policy - Developer Access
resource "aws_iam_group_policy_attachment" "security_engineers_policy" {
  group      = aws_iam_group.security_engineers.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# IAM User
resource "aws_iam_user" "lucy_levi" {
  name = "lucy-levi"
  path = "/users/"
  
  tags = {
    OktaGroup   = "Security Engineers"
    ManagedBy   = "terraform"
    Description = "User synced from Okta"
  }
}

# Add user to group
resource "aws_iam_user_group_membership" "lucy_levi_membership" {
  user   = aws_iam_user.lucy_levi.name
  groups = [aws_iam_group.security_engineers.name]
}