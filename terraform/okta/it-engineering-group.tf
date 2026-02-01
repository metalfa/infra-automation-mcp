# =============================================================================
# Okta Group for IT Engineering (SAML federation)
# =============================================================================

resource "okta_group" "it_engineering" {
  name        = "IT Engineering"
  description = "Maps to AWS IAM group: it-engineering"
}

# Okta Group Rule - Auto-assign users based on department
resource "okta_group_rule" "it_engineering_rule" {
  name              = "it-engineering-auto-assign"
  status            = "ACTIVE"
  group_assignments = [okta_group.it_engineering.id]
  expression_type   = "urn:okta:expression:1.0"
  expression_value  = "user.department==\"IT\""
}