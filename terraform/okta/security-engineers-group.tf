# =============================================================================
# Okta Group Configuration for Security Engineers
# Maps to AWS IAM group: security-engineers
# =============================================================================

resource "okta_group" "security_engineers" {
  name        = "Security Engineers"
  description = "Security Engineering team - Maps to AWS IAM group: security-engineers"
}

# Okta Group Rule - Auto-assign users with Security title
resource "okta_group_rule" "security_engineers_rule" {
  name              = "security-engineers-auto-assign"
  status            = "ACTIVE"
  group_assignments = [okta_group.security_engineers.id]
  expression_type   = "urn:okta:expression:1.0"
  expression_value  = "String.stringContains(user.title, \"Security\")"
}

# =============================================================================
# AWS SAML Provider Integration
# =============================================================================

resource "aws_iam_saml_provider" "okta" {
  name                   = "okta-sso"
  saml_metadata_document = file("${path.module}/okta-metadata.xml")

  tags = {
    ManagedBy = "terraform"
  }
}

# IAM Role for Okta SSO - Security Engineers
resource "aws_iam_role" "okta_security_engineers" {
  name = "okta-security-engineers-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_saml_provider.okta.arn
      }
      Action = "sts:AssumeRoleWithSAML"
      Condition = {
        StringEquals = {
          "SAML:aud" = "https://signin.aws.amazon.com/saml"
        }
      }
    }]
  })

  tags = {
    OktaGroup = "Security Engineers"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "okta_security_engineers_policy" {
  role       = aws_iam_role.okta_security_engineers.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}