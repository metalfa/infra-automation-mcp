# =============================================================================
# Okta Configuration
# Carlos Santana - Red Security Team
# =============================================================================

# Note: User and group already created via Okta API
# This file documents the configuration for reference

# Okta Group for SAML federation
resource "okta_group" "red_security_team" {
  name        = "Red Security Team"
  description = "Red team security engineers - Maps to AWS IAM group: red-security-team"
}

# Okta Group Rule - Auto-assign users based on department
resource "okta_group_rule" "red_security_team_rule" {
  name              = "red-security-team-auto-assign"
  status            = "ACTIVE"
  group_assignments = [okta_group.red_security_team.id]
  expression_type   = "urn:okta:expression:1.0"
  expression_value  = "user.department==\"Red Security\""
}