# =============================================================================
# IT Engineering IAM Group with Okta SSO Integration
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

# IAM User - Caroline Bryant
resource "aws_iam_user" "caroline_bryant" {
  name = "caroline.bryant"
  path = "/users/"
  
  tags = {
    OktaGroup   = "IT Engineering"
    ManagedBy   = "terraform"
    Email       = "caroline.bryant@demoaactivec.com"
    Description = "User synced from Okta"
  }
}

# Add user to group
resource "aws_iam_user_group_membership" "caroline_bryant_membership" {
  user   = aws_iam_user.caroline_bryant.name
  groups = [aws_iam_group.it_engineering.name]
}