# =============================================================================
# Okta User: Emmy Bentley
# =============================================================================

resource "okta_user" "emmy_bentley" {
  email       = "emmy.bentley@demoaactivec.com"
  first_name  = "Emmy"
  last_name   = "Bentley"
  login       = "emmy.bentley@demoaactivec.com"
  department  = "IT"
  title       = "IT System Engineer"
  status      = "ACTIVE"
}

resource "okta_user_group_memberships" "emmy_bentley_groups" {
  user_id = okta_user.emmy_bentley.id
  groups  = [okta_group.it_system_engineering.id]
}
