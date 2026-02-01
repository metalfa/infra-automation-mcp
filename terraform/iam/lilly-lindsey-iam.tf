# =============================================================================
# IAM User with Okta Group Mapping
# =============================================================================

# IAM Group (maps to Okta group: IT Engineering)
resource "aws_iam_group" "it_engineering" {
  name = "it-engineering"
  path = "/users/"
}

# IAM Group Policy - Developer Access
resource "aws_iam_group_policy_attachment" "it_engineering_policy" {
  group      = aws_iam_group.it_engineering.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# IAM User
resource "aws_iam_user" "lilly_lindsey" {
  name = "lilly.lindsey"
  path = "/users/"
  
  tags = {
    OktaGroup   = "IT Engineering"
    ManagedBy   = "terraform"
    Description = "User synced from Okta"
    Email       = "lilly.lindsey@demoaactivec.com"
  }
}

# Add user to group
resource "aws_iam_user_group_membership" "lilly_lindsey_membership" {
  user   = aws_iam_user.lilly_lindsey.name
  groups = [aws_iam_group.it_engineering.name]
}