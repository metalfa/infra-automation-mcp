# Okta User: Metal Fa
resource "okta_user" "metalfa_company_com" {
  first_name = "Metal"
  last_name  = "Fa"
  email      = "metalfa@company.com"
  login      = "metalfa@company.com"
}