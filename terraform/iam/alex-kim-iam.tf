# =============================================================================
# IAM User with Okta Group Mapping
# =============================================================================

# IAM Group (maps to Okta group: Engineering)
resource "aws_iam_group" "developers" {
  name = "developers"
  path = "/users/"
}

# IAM Group Policy - Developer Access
resource "aws_iam_group_policy_attachment" "developers_policy" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# IAM User
resource "aws_iam_user" "alex_kim" {
  name = "alex.kim"
  path = "/users/"
  
  tags = {
    OktaGroup   = "Engineering"
    ManagedBy   = "terraform"
    Description = "User synced from Okta"
  }
}

# Add user to group
resource "aws_iam_user_group_membership" "alex_kim_membership" {
  user   = aws_iam_user.alex_kim.name
  groups = [aws_iam_group.developers.name]
}

# =============================================================================
# Okta Group (for SAML federation)
# =============================================================================

resource "okta_group" "Engineering" {
  name        = "Engineering"
  description = "Maps to AWS IAM group: developers"
}

# Okta Group Rule - Auto-assign users based on department
resource "okta_group_rule" "Engineering_rule" {
  name              = "Engineering-auto-assign"
  status            = "ACTIVE"
  group_assignments = [okta_group.Engineering.id]
  expression_type   = "urn:okta:expression:1.0"
  expression_value  = "user.department==\"Engineering\""
}