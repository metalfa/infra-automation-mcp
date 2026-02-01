# =============================================================================
# Okta Group Configuration
# Maps to AWS IAM group: security-engineering
# =============================================================================

resource "okta_group" "security_engineering" {
  name        = "Security Engineering"
  description = "Security Engineering team - Maps to AWS IAM group: security-engineering"
}

# SAML App Group Assignment
resource "okta_app_group_assignment" "security_engineering_aws" {
  app_id   = okta_app_saml.aws_console.id
  group_id = okta_group.security_engineering.id
  
  profile = jsonencode({
    role = "arn:aws:iam::ACCOUNT_ID:role/security-engineering-role"
  })
}

# Group members output
output "security_engineering_group_id" {
  value       = okta_group.security_engineering.id
  description = "Okta Security Engineering group ID"
}