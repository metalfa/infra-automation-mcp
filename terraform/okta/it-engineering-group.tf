# =============================================================================
# Okta IT Engineering Group Configuration
# =============================================================================

resource "okta_group" "it_engineering" {
  name        = "IT Engineering"
  description = "IT Engineering team - Maps to AWS IAM group: it-engineering"
}

# Okta Group Rule - Auto-assign users based on department
resource "okta_group_rule" "it_engineering_rule" {
  name              = "it-engineering-auto-assign"
  status            = "ACTIVE"
  group_assignments = [okta_group.it_engineering.id]
  expression_type   = "urn:okta:expression:1.0"
  expression_value  = "user.department==\"IT\""
}

# Okta User - Caroline Bryant
resource "okta_user" "caroline_bryant" {
  login      = "caroline.bryant@demoaactivec.com"
  email      = "caroline.bryant@demoaactivec.com"
  first_name = "Caroline"
  last_name  = "Bryant"
  title      = "IT System Engineer"
  department = "IT"

  lifecycle {
    ignore_changes = [password]
  }
}

# Add user to IT Engineering group
resource "okta_group_membership" "caroline_bryant_it_engineering" {
  group_id = okta_group.it_engineering.id
  user_id  = okta_user.caroline_bryant.id
}