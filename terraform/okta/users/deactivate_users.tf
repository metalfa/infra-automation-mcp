# User Deactivation - SOC 2 Compliance Remediation
# Generated: 2026-02-11
# Reason: Inactive account cleanup - accounts never activated/logged in

# Note: This is a declarative approach to user lifecycle management
# All user deactivations should go through this PR process for audit trail

locals {
  deactivation_date = "2026-02-11"
  deactivation_reason = "SOC 2 compliance - account never activated"
  deactivated_by = "faycal@job2resu.me"
}

# Alex Garcia - Deactivation Request
# Status: STAGED → DEPROVISIONED
# Created: 2026-01-28 | Never activated
resource "okta_user" "alex_garcia" {
  status     = "DEPROVISIONED"
  first_name = "Alex"
  last_name  = "Garcia"
  email      = "alex.garcia@activecompainlabinterview.com"
  login      = "alex.garcia@activecompainlabinterview.com"
  
  # Profile attributes preserved for audit trail
  department = "Security"
  title      = "Compliance Analyst"
  
  # Lifecycle management
  lifecycle {
    ignore_changes = [
      # Prevent accidental reactivation
      status,
    ]
  }
}

# Remaining Inactive Users - Pending Review
# Uncomment to deactivate after review/approval

# resource "okta_user" "sarah_chen" {
#   status     = "DEPROVISIONED"
#   first_name = "Sarah"
#   last_name  = "Chen"
#   email      = "sarah.chen@activecompainlabinterview.com"
#   login      = "sarah.chen@activecompainlabinterview.com"
#   department = "Engineering"
#   title      = "VP of Engineering"
# }

# resource "okta_user" "james_wilson" {
#   status     = "DEPROVISIONED"
#   first_name = "James"
#   last_name  = "Wilson"
#   email      = "james.wilson@activecompainlabinterview.com"
#   login      = "james.wilson@activecompainlabinterview.com"
#   department = "IT Operations"
#   title      = "Systems Administrator"
# }

# resource "okta_user" "jennifer_kim" {
#   status     = "DEPROVISIONED"
#   first_name = "Jennifer"
#   last_name  = "Kim"
#   email      = "jennifer.kim@activecompainlabinterview.com"
#   login      = "jennifer.kim@activecompainlabinterview.com"
#   department = "Engineering"
#   title      = "Frontend Engineer"
# }

# resource "okta_user" "caroline_bryant" {
#   status     = "DEPROVISIONED"
#   first_name = "Caroline"
#   last_name  = "Bryant"
#   email      = "caroline.bryant@demoaactivec.com"
#   login      = "caroline.bryant@demoaactivec.com"
#   department = "IT"
#   title      = "IT System Engineer"
# }

# resource "okta_user" "metal_fa" {
#   status     = "DEPROVISIONED"
#   first_name = "Metal"
#   last_name  = "Fa"
#   email      = "metalfa@company.com"
#   login      = "metalfa@company.com"
# }

# Outputs for audit trail
output "deactivation_summary" {
  value = {
    date           = local.deactivation_date
    reason         = local.deactivation_reason
    deactivated_by = local.deactivated_by
    users_deactivated = [
      "alex.garcia@activecompainlabinterview.com",
    ]
  }
}