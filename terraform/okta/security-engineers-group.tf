# =============================================================================
# Okta Group Configuration for AWS Federation
# =============================================================================

resource "okta_group" "security_engineers" {
  name        = "Security Engineers"
  description = "Security Engineering team - maps to AWS IAM group: security-engineers"
}

# Okta Group Rule - Auto-assign users based on title
resource "okta_group_rule" "security_engineers_rule" {
  name              = "security-engineers-auto-assign"
  status            = "ACTIVE"
  group_assignments = [okta_group.security_engineers.id]
  expression_type   = "urn:okta:expression:1.0"
  expression_value  = "user.title==\"Security Engineer\""
}