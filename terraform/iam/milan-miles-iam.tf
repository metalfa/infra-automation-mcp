# =============================================================================
# IAM User with Okta Group Mapping
# Onboarding: Milan Miles (Security Engineer)
# =============================================================================

# IAM Group (maps to Okta group: Security Engineering)
resource "aws_iam_group" "security_engineering" {
  name = "security-engineering"
  path = "/users/"
}

# IAM Group Policy - Security Engineering Access
resource "aws_iam_group_policy_attachment" "security_engineering_policy" {
  group      = aws_iam_group.security_engineering.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Additional Security-specific policies
resource "aws_iam_group_policy_attachment" "security_engineering_security_audit" {
  group      = aws_iam_group.security_engineering.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# IAM User
resource "aws_iam_user" "milan_miles" {
  name = "milan.miles"
  path = "/users/"
  
  tags = {
    Email       = "milan.miles@demoaactivec.com"
    OktaGroup   = "Security Engineering"
    Team        = "Security Engineering"
    Title       = "Security Engineer"
    ManagedBy   = "terraform"
    Description = "User synced from Okta"
  }
}

# Add user to group
resource "aws_iam_user_group_membership" "milan_miles_membership" {
  user   = aws_iam_user.milan_miles.name
  groups = [aws_iam_group.security_engineering.name]
}