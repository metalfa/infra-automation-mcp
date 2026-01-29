# =============================================================================
# Okta Group (for SAML federation)
# =============================================================================

resource "okta_group" "okta_platform_developers" {
  name        = "okta-platform-developers"
  description = "Maps to AWS IAM group: platform-developers"
}

# Okta Group Rule - Auto-assign users based on department
resource "okta_group_rule" "okta_platform_developers_rule" {
  name              = "okta-platform-developers-auto-assign"
  status            = "ACTIVE"
  group_assignments = [okta_group.okta_platform_developers.id]
  expression_type   = "urn:okta:expression:1.0"
  expression_value  = "user.department==\"Engineering\""
}