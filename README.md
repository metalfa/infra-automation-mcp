# Infrastructure Automation MCP

## AI-Powered CI/CD Pipeline for Okta, AWS & Terraform

**Transform infrastructure management from CLI commands to natural conversations.**

This MCP (Model Context Protocol) server enables AI assistants like Claude to manage enterprise infrastructure through natural language. Instead of writing Terraform, clicking through AWS consoles, or memorizing CLI commands, simply describe what you need.

---

## 🎯 What Problem Does This Solve?

### Traditional Infrastructure Management

# Create a user - requires knowing Okta CLI
okta users create --firstName Bruce --lastName Lee --email bruce@demoac.com

# Find the group ID
okta groups list | grep "Engineering"

# Add user to group
okta groups members add 00g123456789 00u987654321

# Write Terraform manually
vim terraform/users.tf

# Create PR with multiple git commands
git checkout -b add-user-Bruce
git add .
git commit -m "Add user Bruce Lee"
git push origin add-user-Bruce
gh pr create --title "Add user Bruce Lee"

# Wait for approval, then apply
terraform apply

**Time: 30-45 minutes | Error-prone | No audit trail**

### With This MCP

You: "Create a new user bruce.lee@demoac.com in the Engineering department,
      add them to the aws-developers group, generate Terraform code, and create a PR"

Claude: Done! I've:
        ✅ Created Bruce Lee in Okta
        ✅ Added to aws-developers group
        ✅ Generated production-ready Terraform
        ✅ Created PR #47 for review
        ✅ Sent Slack notification to approvers
```
**Time: 30 seconds | Error-free | Complete audit trail**

```

## 🚀 Features

### Identity Management (Okta)
| Feature | Tool | Description |
|---------|------|-------------|
| List Users | `okta_list_users` | Search and list all Okta users |
| List Groups | `okta_list_groups` | View all groups and memberships |
| Create User | `okta_create_user` | Create users with full profile + auto-generate Terraform |
| Create Group | `okta_create_group` | Create groups + generate IaC configuration |

### AWS Infrastructure
| Feature | Tool | Description |
|---------|------|-------------|
| List EKS Clusters | `aws_list_eks_clusters` | View all Kubernetes clusters |
| Describe Cluster | `aws_describe_cluster` | Get detailed cluster information |
| List IAM Roles | `aws_list_iam_roles` | Audit IAM roles and policies |
| Get Identity | `aws_get_identity` | Verify current AWS credentials |

### Terraform Generation
| Feature | Tool | Description |
|---------|------|-------------|
| Generate EC2 | `terraform_generate_ec2_free_tier` | Create free-tier EC2 instance config |
| Generate IAM + Okta | `terraform_generate_iam_user_with_okta` | IAM user with Okta SSO mapping |
| Generate EKS | `terraform_generate_eks` | Full EKS cluster configuration |
| Generate IAM Role | `terraform_generate_iam_role` | IAM role with trust policies |

### CI/CD Pipeline
| Feature | Tool | Description |
|---------|------|-------------|
| Create PR | `create_infrastructure_pr` | Auto-create GitHub PR with changes |
| List PRs | `list_open_prs` | View pending infrastructure changes |
| Pipeline Status | `list_pipeline_runs` | Monitor CI/CD workflow runs |
| Full Workflow | `complete_infrastructure_workflow` | End-to-end: Generate → PR → Notify |

### Compliance & Security
| Feature | Tool | Description |
|---------|------|-------------|
| Access Review | `generate_access_review` | SOC2/ISO27001 compliance reports |
| User Access Audit | `check_user_access` | Complete access report for any user |

### Notifications
| Feature | Tool | Description |
|---------|------|-------------|
| Slack Alerts | `send_slack_notification` | Notify teams of infrastructure changes |

---

## 🏗️ Architecture

┌─────────────────────────────────────────────────────────────────────────────┐
│                           USER INTERFACE                                     │
│                         Claude Desktop App                                   │
│                    "Create an EC2 instance for the dev team"                │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │ Natural Language
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     INFRASTRUCTURE AUTOMATION MCP                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ Okta Client │  │ AWS Client  │  │  Terraform  │  │GitHub Client│        │
│  │             │  │             │  │  Generator  │  │             │        │
│  │ • Users     │  │ • EC2       │  │             │  │ • PRs       │        │
│  │ • Groups    │  │ • IAM       │  │ • EC2       │  │ • Branches  │        │
│  │ • Apps      │  │ • EKS       │  │ • IAM       │  │ • Files     │        │
│  └──────┬──────┘  └──────┬──────┘  │ • EKS       │  └──────┬──────┘        │
│         │                │         │ • VPC       │         │               │
│         │                │         └──────┬──────┘         │               │
└─────────┼────────────────┼────────────────┼────────────────┼───────────────┘
          │                │                │                │
          ▼                ▼                ▼                ▼
   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
   │    OKTA     │  │     AWS     │  │  TERRAFORM  │  │   GITHUB    │
   │             │  │             │  │    STATE    │  │             │
   │ Identity    │  │ EC2 / IAM   │  │     (S3)    │  │ Actions     │
   │ Provider    │  │ EKS / VPC   │  │             │  │ CI/CD       │
   └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘
                                                             │
                                                             ▼
                                                      ┌─────────────┐
                                                      │   SLACK     │
                                                      │ Notifications│
                                                      └─────────────┘
```
```

## 🔄 CI/CD Pipeline Flow

┌──────────────────────────────────────────────────────────────────────────┐
│                        GITOPS WORKFLOW                                    │
└──────────────────────────────────────────────────────────────────────────┘

  Developer Request          MCP Processing            GitHub Actions
  ─────────────────         ──────────────            ──────────────
        │                         │                         │
        ▼                         │                         │
┌───────────────┐                 │                         │
│ "Create EC2   │                 │                         │
│  instance"    │                 │                         │
└───────┬───────┘                 │                         │
        │                         ▼                         │
        │               ┌───────────────────┐               │
        └──────────────►│ Generate Terraform │               │
                        │ Configuration      │               │
                        └─────────┬─────────┘               │
                                  │                         │
                                  ▼                         │
                        ┌───────────────────┐               │
                        │ Create GitHub PR   │               │
                        └─────────┬─────────┘               │
                                  │                         │
                                  ▼                         │
                        ┌───────────────────┐               │
                        │ Send Slack Alert   │               │
                        │ to Approvers       │               │
                        └─────────┬─────────┘               │
                                  │                         │
        ┌─────────────────────────┘                         │
        ▼                                                   │
┌───────────────┐                                           │
│ Team Reviews  │                                           │
│ & Approves PR │                                           │
└───────┬───────┘                                           │
        │                                                   │
        ▼                                                   │
┌───────────────┐                                           │
│   Merge PR    │───────────────────────────────────────────┤
└───────────────┘                                           │
                                                            ▼
                                              ┌───────────────────────┐
                                              │ GitHub Actions        │
                                              │ ┌───────────────────┐ │
                                              │ │ terraform init    │ │
                                              │ └─────────┬─────────┘ │
                                              │           ▼           │
                                              │ ┌───────────────────┐ │
                                              │ │ terraform plan    │ │
                                              │ └─────────┬─────────┘ │
                                              │           ▼           │
                                              │ ┌───────────────────┐ │
                                              │ │ terraform apply   │ │
                                              │ └─────────┬─────────┘ │
                                              │           ▼           │
                                              │ ┌───────────────────┐ │
                                              │ │ Wait 3 minutes    │ │
                                              │ └─────────┬─────────┘ │
                                              │           ▼           │
                                              │ ┌───────────────────┐ │
                                              │ │ terraform destroy │ │
                                              │ │ (auto-cleanup)    │ │
                                              │ └───────────────────┘ │
                                              └───────────────────────┘
```

---

## 📦 Installation

### Prerequisites

- Python 3.10+
- Terraform 1.6+
- AWS CLI configured
- Okta organization with API access
- GitHub account
- Claude Desktop

### Quick Start
```
# Clone the repository
git clone https://github.com/metalfa/infra-automation-mcp.git
cd infra-automation-mcp

# Create virtual environment
python -m venv venv

# Activate (Windows)
.\venv\Scripts\Activate.ps1

# Activate (Mac/Linux)
source venv/bin/activate

# Install the package
pip install -e .
```

### Configuration

1. **Copy the environment template:**
```bash
   cp .env.example .env
```

2. **Edit `.env` with your credentials:**
```env
   # Okta
   OKTA_BASE_URL=https://your-org.okta.com
   OKTA_API_TOKEN=your-okta-token

   # AWS
   AWS_REGION=us-east-1
   AWS_ACCESS_KEY_ID=your-access-key
   AWS_SECRET_ACCESS_KEY=your-secret-key

   # GitHub
   GITHUB_TOKEN=your-github-pat
   GITHUB_REPO=your-username/infra-automation-mcp

   # Slack (optional)
   SLACK_WEBHOOK_URL=https://hooks.slack.com/services/xxx

   # Terraform
   TERRAFORM_WORKING_DIR=./terraform
```

3. **Configure Claude Desktop:**

   Edit `%APPDATA%\Claude\claude_desktop_config.json` (Windows) or `~/Library/Application Support/Claude/claude_desktop_config.json` (Mac):
```json
   {
     "mcpServers": {
       "infra-automation": {
         "command": "C:\\path\\to\\venv\\Scripts\\python.exe",
         "args": ["-m", "infra_automation_mcp.server"],
         "cwd": "C:\\path\\to\\infra-automation-mcp",
         "env": {
           "OKTA_BASE_URL": "https://your-org.okta.com",
           "OKTA_API_TOKEN": "your-token",
           "AWS_REGION": "us-east-1",
           "AWS_ACCESS_KEY_ID": "your-key",
           "AWS_SECRET_ACCESS_KEY": "your-secret",
           "GITHUB_TOKEN": "your-github-token",
           "GITHUB_REPO": "your-username/infra-automation-mcp"
         }
       }
     }
   }
```

4. **Restart Claude Desktop**

---

## 🧪 Testing

### Verify MCP is Running
```
python -m infra_automation_mcp.server
# Should output: Starting Infrastructure Automation MCP Server...
```

### Test in Claude Desktop

Open Claude Desktop and try:
```
What infrastructure automation tools do you have available?
```

---

## 💬 Example Conversations

### Onboard a New Employee
```
Create a new user sarah.chen@demoac.com (Sarah Chen, Platform Engineer) 
in the Engineering department, add her to the platform-team group, 
and generate Terraform code for her AWS IAM access.
```

### Provision Development Infrastructure
```
Generate Terraform configuration for:
1. A free-tier EC2 instance called "dev-workstation"
2. An IAM role with developer permissions
3. Security group allowing SSH and HTTP

Then create a PR with these changes.
```

### Security Audit
```
Generate a comprehensive access review report for our SOC2 audit. 
Include all Okta users, their group memberships, and any security 
recommendations.
```

### Full Workflow Demo
```
I need to set up infrastructure for a new "Data Science" team:
1. Create an Okta group "data-science-team"
2. Create user alex.kim@demoac.com (Alex Kim, Data Scientist)
3. Generate EC2 instance Terraform for their workstation
4. Generate IAM configuration with S3 and SageMaker access
5. Create a PR with all changes
6. Send a Slack notification to the platform-team
```

---

## 🔐 Security Features

| Feature | Implementation |
|---------|----------------|
| **No Hardcoded Secrets** | All credentials via environment variables |
| **GitOps Workflow** | All changes through PR review |
| **Audit Trail** | Complete history in Git |
| **Auto-Destroy** | Demo resources auto-delete after 3 minutes |
| **Least Privilege** | IAM roles scoped to minimum required |
| **State Encryption** | Terraform state encrypted in S3 |
| **MFA Ready** | Okta policies support MFA enforcement |

---

## 📁 Project Structure
```
infra-automation-mcp/
├── .github/
│   └── workflows/
│       └── terraform-deploy.yml    # CI/CD pipeline
├── src/
│   └── infra_automation_mcp/
│       ├── __init__.py
│       ├── server.py               # MCP server & tools
│       ├── okta_client.py          # Okta API client
│       ├── aws_client.py           # AWS API client
│       ├── terraform_client.py     # Terraform generator
│       ├── github_client.py        # GitHub API client
│       └── slack_client.py         # Slack notifications
├── terraform/
│   └── environments/
│       └── dev/
│           └── main.tf             # Terraform configuration
├── .env.example                    # Environment template
├── .gitignore
├── pyproject.toml
└── README.md
```

---
```

## 🛠️ GitHub Actions Pipeline

The included CI/CD pipeline automatically:

1. **On Pull Request:**
   - Runs `terraform fmt` (formatting check)
   - Runs `terraform validate` (syntax check)
   - Runs `terraform plan` (preview changes)
   - Posts plan as PR comment

2. **On Merge to Main:**
   - Runs `terraform apply` (creates resources)
   - Waits 3 minutes (demo time)
   - Runs `terraform destroy` (cleanup)
   - Sends Slack notifications

---

## 🎓 Why This Approach?

| Traditional DevOps | AI-Powered DevOps |
|--------------------|-------------------|
| Learn multiple CLIs | Natural language |
| Write YAML/HCL manually | Auto-generated code |
| Context switch between tools | Single conversation |
| Error-prone copy/paste | Validated configurations |
| Manual documentation | Self-documenting |
| Tribal knowledge | Accessible to everyone |

### Business Value

- **90% faster** infrastructure provisioning
- **Zero** manual errors in configuration
- **100%** audit trail compliance
- **Democratized** infrastructure access
- **Reduced** onboarding time for new engineers

---

## 🗺️ Roadmap

- [x] Okta user and group management
- [x] AWS EC2 and IAM provisioning
- [x] Terraform code generation
- [x] GitHub PR automation
- [x] Slack notifications
- [x] Auto-destroy for cost control
- [ ] Azure AD integration
- [ ] Intune integration
- [ ] Kandji AD integration
- [ ] Ansible integration
- [ ] Kubernetes manifest generation
- [ ] Cost estimation (Infracost)
- [ ] Policy as Code (OPA/Sentinel)
- [ ] Multi-cloud support

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 👤 Author

**Faycal** - Systems Engineer

- GitHub: [@metalfa](https://github.com/metalfa)
- LinkedIn: [https://www.linkedin.com/in/faycal-ben-sassi/]
- Email: [bensassi.faysel@gmail.com]

---

## 🙏 Acknowledgments

- [Anthropic](https://anthropic.com) - Claude AI and MCP Protocol
- [HashiCorp](https://hashicorp.com) - Terraform
- [Okta](https://okta.com) - Identity Management
- [AWS](https://aws.amazon.com) - Cloud Infrastructure

---

<p align="center">
  <strong>Built to demonstrate AI-driven infrastructure automation</strong><br>
  <em>"The best way to predict the future is to build it—and the future of DevOps is conversational"</em>
</p>