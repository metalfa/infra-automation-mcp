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
resource "aws_iam_user" "bruce_lee" {
  name = "bruce.lee"
  path = "/users/"
  
  tags = {
    OktaGroup   = "Security Engineers"
    ManagedBy   = "terraform"
    Description = "User synced from Okta"
    Email       = "bruce.lee@demoac.com"
  }
}

# Add user to group
resource "aws_iam_user_group_membership" "bruce_lee_membership" {
  user   = aws_iam_user.bruce_lee.name
  groups = [aws_iam_group.security_engineers.name]
}

# =============================================================================
# Okta Group (for SAML federation)
# =============================================================================

resource "okta_group" "security_engineers" {
  name        = "Security Engineers"
  description = "Maps to AWS IAM group: security-engineers"
}

# Okta Group Rule - Auto-assign users based on department
resource "okta_group_rule" "security_engineers_rule" {
  name              = "Security Engineers-auto-assign"
  status            = "ACTIVE"
  group_assignments = [okta_group.security_engineers.id]
  expression_type   = "urn:okta:expression:1.0"
  expression_value  = "user.department==\"Security\""
}