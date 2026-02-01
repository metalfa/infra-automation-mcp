# =============================================================================
# IAM User with Okta Group Mapping
# Lucy Spacy - Security Engineer
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

# Additional Security Tools Policy
resource "aws_iam_group_policy" "security_engineers_custom" {
  name  = "security-engineers-custom-policy"
  group = aws_iam_group.security_engineers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "securityhub:*",
          "guardduty:*",
          "inspector:*",
          "config:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM User
resource "aws_iam_user" "lucy_spacy" {
  name = "lucy.spacy"
  path = "/users/"
  
  tags = {
    Email       = "lucy.spacy@demoaactivec.com"
    OktaGroup   = "Security Engineers"
    Department  = "Security"
    ManagedBy   = "terraform"
    Description = "User synced from Okta"
  }
}

# Add user to group
resource "aws_iam_user_group_membership" "lucy_spacy_membership" {
  user   = aws_iam_user.lucy_spacy.name
  groups = [aws_iam_group.security_engineers.name]
}