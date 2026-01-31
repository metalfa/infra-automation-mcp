# Infrastructure Automation MCP

## AI-Powered CI/CD Pipeline for Okta & AWS

This MCP (Model Context Protocol) server enables **natural language infrastructure management**. Instead of writing YAML, clicking through consoles, or memorizing CLI commands, simply describe what you want.

---

## The Innovation

### Traditional DevOps

# Create a user - requires knowing Okta CLI
okta users create --firstName John --lastName Smith --email john@company.com

# Add to group - need to lookup group ID first
okta groups members add 00g123456789 00u987654321

# Generate Terraform - write HCL manually
vim terraform/users.tf

# Create PR - multiple git commands
git checkout -b add-user-john
git add .
git commit -m "Add user John Smith"
git push origin add-user-john
gh pr create --title "Add user John Smith" --body "..."
`

### With This MCP
`
You: "Create a new user john.smith@company.com in the Engineering department 
      and add them to the aws-developers group"

Claude: Done! I've:
        1. Created the user in Okta
        2. Added them to the aws-developers group
        3. Generated Terraform configuration
        4. Created PR #47 for review
`

---

## Features

### Okta Management
| Command | Description |
|---------|-------------|
| okta_list_users | Search and list users |
| okta_list_groups | List all groups |
| okta_create_user | Create user + generate Terraform |
| okta_create_group | Create group + generate Terraform |

### AWS Management
| Command | Description |
|---------|-------------|
| ws_list_eks_clusters | List EKS clusters |
| ws_describe_cluster | Get cluster details |
| ws_list_iam_roles | List IAM roles |
| ws_get_identity | Show current AWS identity |

### Terraform Operations
| Command | Description |
|---------|-------------|
| 	erraform_generate_eks | Generate EKS cluster config |
| 	erraform_generate_iam_role | Generate IAM role config |

### CI/CD Pipeline
| Command | Description |
|---------|-------------|
| create_infrastructure_pr | Create PR with changes |
| list_open_prs | Show pending PRs |
| list_pipeline_runs | Show recent CI/CD runs |

### Compliance
| Command | Description |
|---------|-------------|
| generate_access_review | SOC2/ISO27001 compliance report |
| check_user_access | Full access report for a user |

---

## Architecture
`

                         Claude Desktop                               
                    (Natural Language Interface)                      

                                      
                                      

                  Infrastructure Automation MCP                       
          
   Okta Client     AWS Client     TF Client     GH Client   
          

                                                         
                                                         
                    
       Okta            AWS         Terraform     GitHub  
       API             API            CLI          API   
                    
`

---

## Example Conversations

### Onboarding a New Employee
`
You: Create user sarah.jones@company.com, she's a Senior Engineer 
     in the Platform team, add her to aws-developers and k8s-admins groups

Claude: I've created Sarah Jones's account:
        - Email: sarah.jones@company.com
        - Department: Platform
        - Title: Senior Engineer
        - Groups: aws-developers, k8s-admins
        - Status: ACTIVE (welcome email sent)
        
        Terraform config generated. Create PR? [Yes/No]
`

### Infrastructure Review
`
You: Show me all users with admin access and when they last logged in

Claude: ## Admin Access Review
        
        ### Okta - aws-admins group (3 users)
        - john.doe@company.com - Last login: 2 hours ago
        - jane.smith@company.com - Last login: 1 day ago
        - bob.wilson@company.com - Last login: 45 days ago 
        
        Recommendation: bob.wilson hasn't logged in for 45 days.
        Consider reviewing their access level.
`

### Compliance Reporting
`
You: Generate an access review report for our SOC2 audit

Claude: # Access Review Report
        Generated: 2024-01-27
        
        ## Summary
        - Total Okta Users: 150
        - Active: 142
        - Inactive: 8 (review needed)
        
        ## High-Privilege Access
        - Admin roles: 5 users
        - EKS clusters: 3
        
        ## Recommendations
        1. Deactivate 8 inactive users
        2. Review admin access quarterly
        3. Enable MFA for remaining 12 users
        
        [Download Full Report PDF]
`

---

## Installation
`ash
# Clone the repository
git clone https://github.com/yourusername/infra-automation-mcp.git
cd infra-automation-mcp

# Create virtual environment
python -m venv venv
source venv/bin/activate  # or .\venv\Scripts\Activate.ps1 on Windows

# Install
pip install -e .

# Configure
cp .env.example .env
# Edit .env with your credentials
`

---

## Claude Desktop Configuration

Add to %APPDATA%\Claude\claude_desktop_config.json:
`json
{
  \"mcpServers\": {
    \"infra-automation\": {
      \"command\": \"C:\\\\path\\\\to\\\\venv\\\\Scripts\\\\python.exe\",
      \"args\": [\"-m\", \"infra_automation_mcp.server\"],
      \"cwd\": \"C:\\\\path\\\\to\\\\infra-automation-mcp\",
      \"env\": {
        \"OKTA_BASE_URL\": \"https://your-org.okta.com\",
        \"OKTA_API_TOKEN\": \"your-token\",
        \"AWS_REGION\": \"us-east-1\",
        \"AWS_ACCESS_KEY_ID\": \"your-key\",
        \"AWS_SECRET_ACCESS_KEY\": \"your-secret\",
        \"GITHUB_TOKEN\": \"your-github-token\",
        \"GITHUB_REPO\": \"your-org/infrastructure\"
      }
    }
  }
}
`

---

## Why This Approach?

| Traditional CI/CD | MCP-Powered CI/CD |
|-------------------|-------------------|
| Steep learning curve | Natural language |
| Context switching | Single interface |
| Manual documentation | Self-documenting |
| Error-prone commands | Guided workflows |
| Siloed tools | Unified platform |

---

## Security

- No credentials in code
- Environment variable configuration
- Audit logging of all operations
- PR-based change approval
- MFA enforcement via Okta policies

---

## For ActiveCampaign Reviewers

This project demonstrates:

1. **AI-First Thinking** - Leveraging LLMs for DevOps
2. **Infrastructure as Code** - Terraform generation
3. **CI/CD Automation** - GitHub Actions integration
4. **Identity Management** - Okta expertise
5. **Cloud Infrastructure** - AWS/EKS knowledge
6. **Security Mindset** - Zero Trust, MFA, audit trails
7. **Innovation** - Novel approach to a common problem

---

## Author

**Faycal** - Systems Engineer Candidate

*\"The best way to predict the future is to build it.\"*
