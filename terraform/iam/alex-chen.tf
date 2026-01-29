# =============================================================================
# IAM User with Okta Group Mapping
# =============================================================================

# IAM Group (maps to Okta group: okta-platform-developers)
resource "aws_iam_group" "platform_developers" {
  name = "platform-developers"
  path = "/users/"
}

# IAM Group Policy - Developer Access
resource "aws_iam_group_policy_attachment" "platform_developers_policy" {
  group      = aws_iam_group.platform_developers.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# IAM User
resource "aws_iam_user" "alex_chen" {
  name = "alex.chen"
  path = "/users/"
  
  tags = {
    OktaGroup   = "okta-platform-developers"
    ManagedBy   = "terraform"
    Description = "User synced from Okta"
  }
}

# Add user to group
resource "aws_iam_user_group_membership" "alex_chen_membership" {
  user   = aws_iam_user.alex_chen.name
  groups = [aws_iam_group.platform_developers.name]
}