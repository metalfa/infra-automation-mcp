# =============================================================================
# IAM Configuration for Security Engineers
# Integrated with Okta SSO
# =============================================================================

# IAM Group (maps to Okta group: Security Engineers)
resource "aws_iam_group" "security_engineers" {
  name = "security-engineers"
  path = "/users/"
}

# IAM Group Policy - PowerUser Access for Security Engineers
resource "aws_iam_group_policy_attachment" "security_engineers_policy" {
  group      = aws_iam_group.security_engineers.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# IAM User: lucy-lee
resource "aws_iam_user" "lucy_lee" {
  name = "lucy-lee"
  path = "/users/"
  
  tags = {
    OktaGroup   = "Security Engineers"
    Email       = "lucy.lee@demoaactivec.com"
    ManagedBy   = "terraform"
    Description = "User synced from Okta"
  }
}

# Add user to group
resource "aws_iam_user_group_membership" "lucy_lee_membership" {
  user   = aws_iam_user.lucy_lee.name
  groups = [aws_iam_group.security_engineers.name]
}