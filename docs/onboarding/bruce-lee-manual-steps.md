# Manual Onboarding Steps for Bruce Lee

## Okta User Creation (Required)

Due to permission constraints with the domain `demoactivecampaign.com`, the Okta user must be created manually through the Okta admin console.

### User Details
- **Email**: bruce.lee@demoactivecampaign.com
- **First Name**: Bruce
- **Last Name**: Lee
- **Title**: Security Engineer
- **Department**: Security

### Steps
1. Log into Okta Admin Console
2. Navigate to Directory → People
3. Click "Add Person"
4. Fill in the user details above
5. Select "Send user activation email now"
6. Click "Save"

### Automatic Group Assignment
Once the user is created, they will automatically be assigned to the "Security" Okta group via the group rule that matches `user.department == "Security"`.

### Post-Creation
1. Bruce will receive an activation email
2. After activation, he can SSO into AWS Console
3. He will have PowerUserAccess via the security-engineers IAM group
4. He can SSH into bruce-lee-box EC2 instance

## Security Hardening (Recommended)

Before approving the terraform apply:
1. Update SSH security group to restrict to office IP range
2. Consider changing IAM policy from PowerUserAccess to SecurityAudit for security team members
3. Add SSH key pair to EC2 instance configuration
4. Enable CloudWatch monitoring for the instance