# =============================================================================
# Okta Group: IT System Engineering
# =============================================================================

resource "okta_group" "it_system_engineering" {
  name        = "IT System Engineering"
  description = "Group for IT System Engineers - Maps to AWS IAM group: it-system-engineering"
}

# Auto-assign rule based on department/title
resource "okta_group_rule" "it_system_engineering_rule" {
  name              = "it-system-engineering-auto-assign"
  status            = "ACTIVE"
  group_assignments = [okta_group.it_system_engineering.id]
  expression_type   = "urn:okta:expression:1.0"
  expression_value  = "user.title==\"IT System Engineer\""
}
