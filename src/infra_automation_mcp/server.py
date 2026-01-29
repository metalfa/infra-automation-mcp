"""Infrastructure Automation MCP Server - AI-Powered DevOps"""

import sys
import json
from datetime import datetime
from mcp.server.fastmcp import FastMCP
from pydantic import BaseModel, Field
from typing import Optional

# Import our clients
from infra_automation_mcp.okta_client import OktaClient, OktaAPIError
from infra_automation_mcp.terraform_client import TerraformClient, TerraformError
from infra_automation_mcp.github_client import GitHubClient, GitHubError
from infra_automation_mcp.aws_client import AWSClient, AWSError

mcp = FastMCP(
    "infra_automation_mcp",
    description="AI-Powered Infrastructure Automation - Manage Okta, Terraform, AWS, and GitHub through natural language"
)

# =============================================================================
# INPUT MODELS
# =============================================================================

class CreateUserInput(BaseModel):
    email: str = Field(..., description="User's email address")
    first_name: str = Field(..., description="First name")
    last_name: str = Field(..., description="Last name")
    department: Optional[str] = Field(None, description="Department")
    title: Optional[str] = Field(None, description="Job title")
    groups: Optional[list] = Field(None, description="Groups to add user to")
    create_pr: bool = Field(True, description="Create a PR with Terraform config")

class CreateGroupInput(BaseModel):
    name: str = Field(..., description="Group name")
    description: Optional[str] = Field(None, description="Group description")
    create_pr: bool = Field(True, description="Create a PR with Terraform config")

class CreateEKSClusterInput(BaseModel):
    name: str = Field(..., description="Cluster name")
    environment: str = Field(..., description="Environment (dev, staging, prod)")
    node_count: int = Field(2, description="Number of worker nodes")
    instance_type: str = Field("t3.medium", description="EC2 instance type for nodes")

class TerraformPlanInput(BaseModel):
    environment: str = Field(..., description="Environment to plan (dev, prod)")

class TerraformApplyInput(BaseModel):
    environment: str = Field(..., description="Environment to apply (dev, prod)")
    auto_approve: bool = Field(False, description="Auto-approve without confirmation")

class CreatePRInput(BaseModel):
    title: str = Field(..., description="PR title")
    description: str = Field(..., description="PR description")
    branch_name: str = Field(..., description="Branch name to create")
    files: dict = Field(..., description="Dict of filepath -> content")

class AccessReviewInput(BaseModel):
    scope: str = Field("all", description="Scope: 'all', 'okta', 'aws', or specific group/role")

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def _format_error(e: Exception) -> str:
    return f"Error: {str(e)}"

# =============================================================================
# OKTA TOOLS
# =============================================================================

@mcp.tool(name="okta_list_users")
async def okta_list_users(search: Optional[str] = None, limit: int = 20) -> str:
    """List users in Okta. Optionally search by name or email."""
    try:
        async with OktaClient() as client:
            users = await client.list_users(search=search, limit=limit)
            if not users:
                return "No users found."
            
            lines = [f"## Okta Users ({len(users)} found)\n"]
            for u in users:
                p = u.get("profile", {})
                lines.append(f"- **{p.get('firstName')} {p.get('lastName')}** ({p.get('email')})")
                lines.append(f"  - Status: {u.get('status')} | Dept: {p.get('department', 'N/A')}")
            return "\n".join(lines)
    except Exception as e:
        return _format_error(e)

@mcp.tool(name="okta_list_groups")
async def okta_list_groups(search: Optional[str] = None) -> str:
    """List groups in Okta. Optionally search by name."""
    try:
        async with OktaClient() as client:
            groups = await client.list_groups(search=search)
            if not groups:
                return "No groups found."
            
            lines = [f"## Okta Groups ({len(groups)} found)\n"]
            for g in groups:
                p = g.get("profile", {})
                lines.append(f"- **{p.get('name')}** ({g.get('id')})")
                lines.append(f"  - Type: {g.get('type')} | {p.get('description', 'No description')}")
            return "\n".join(lines)
    except Exception as e:
        return _format_error(e)

@mcp.tool(name="okta_create_user")
async def okta_create_user(params: CreateUserInput) -> str:
    """Create a new user in Okta and optionally generate Terraform config as a PR."""
    try:
        results = []
        
        # Create user directly in Okta
        async with OktaClient() as client:
            user = await client.create_user(
                email=params.email,
                first_name=params.first_name,
                last_name=params.last_name,
                department=params.department,
                title=params.title
            )
            results.append(f"## User Created in Okta\n")
            results.append(f"- **Name:** {params.first_name} {params.last_name}")
            results.append(f"- **Email:** {params.email}")
            results.append(f"- **ID:** {user.get('id')}")
            results.append(f"- **Status:** {user.get('status')}")
            
            # Add to groups if specified
            if params.groups:
                user_id = user.get('id')
                groups = await client.list_groups()
                for group_name in params.groups:
                    for g in groups:
                        if g.get('profile', {}).get('name', '').lower() == group_name.lower():
                            await client.add_user_to_group(g.get('id'), user_id)
                            results.append(f"- Added to group: **{group_name}**")
                            break

        # Generate Terraform config and create PR
        if params.create_pr:
            tf = TerraformClient()
            config = tf.generate_okta_user_config(
                email=params.email,
                first_name=params.first_name,
                last_name=params.last_name,
                department=params.department,
                groups=params.groups
            )
            results.append(f"\n## Terraform Configuration Generated\n")
            results.append(f"`hcl\n{config}\n`")
            results.append(f"\n*Create a PR to add this to your infrastructure code.*")
        
        return "\n".join(results)
    except Exception as e:
        return _format_error(e)

@mcp.tool(name="okta_create_group")
async def okta_create_group(params: CreateGroupInput) -> str:
    """Create a new group in Okta and optionally generate Terraform config."""
    try:
        results = []
        
        async with OktaClient() as client:
            group = await client.create_group(name=params.name, description=params.description)
            results.append(f"## Group Created in Okta\n")
            results.append(f"- **Name:** {params.name}")
            results.append(f"- **ID:** {group.get('id')}")
            results.append(f"- **Description:** {params.description or 'N/A'}")

        if params.create_pr:
            tf = TerraformClient()
            config = tf.generate_okta_group_config(name=params.name, description=params.description)
            results.append(f"\n## Terraform Configuration\n")
            results.append(f"`hcl\n{config}\n`")
        
        return "\n".join(results)
    except Exception as e:
        return _format_error(e)

# =============================================================================
# AWS TOOLS
# =============================================================================

@mcp.tool(name="aws_list_eks_clusters")
async def aws_list_eks_clusters() -> str:
    """List all EKS clusters in the AWS account."""
    try:
        aws = AWSClient()
        clusters = aws.list_clusters()
        
        if not clusters:
            return "No EKS clusters found."
        
        lines = [f"## EKS Clusters ({len(clusters)} found)\n"]
        for name in clusters:
            details = aws.describe_cluster(name)
            lines.append(f"### {name}")
            lines.append(f"- **Status:** {details['status']}")
            lines.append(f"- **Version:** {details['version']}")
            lines.append(f"- **Endpoint:** {details['endpoint'][:50]}...")
            lines.append("")
        
        return "\n".join(lines)
    except Exception as e:
        return _format_error(e)

@mcp.tool(name="aws_describe_cluster")
async def aws_describe_cluster(cluster_name: str) -> str:
    """Get detailed information about an EKS cluster."""
    try:
        aws = AWSClient()
        cluster = aws.describe_cluster(cluster_name)
        nodegroups = aws.list_nodegroups(cluster_name)
        
        lines = [f"## EKS Cluster: {cluster_name}\n"]
        lines.append(f"- **Status:** {cluster['status']}")
        lines.append(f"- **Version:** {cluster['version']}")
        lines.append(f"- **Created:** {cluster['created_at']}")
        lines.append(f"- **VPC:** {cluster['vpc_id']}")
        lines.append(f"- **Endpoint:** {cluster['endpoint']}")
        lines.append(f"\n### Node Groups ({len(nodegroups)})")
        
        for ng_name in nodegroups:
            ng = aws.describe_nodegroup(cluster_name, ng_name)
            lines.append(f"\n**{ng_name}**")
            lines.append(f"- Instance Types: {', '.join(ng['instance_types'])}")
            lines.append(f"- Nodes: {ng['desired_size']} (min: {ng['min_size']}, max: {ng['max_size']})")
            lines.append(f"- Status: {ng['status']}")
        
        return "\n".join(lines)
    except Exception as e:
        return _format_error(e)

@mcp.tool(name="aws_list_iam_roles")
async def aws_list_iam_roles() -> str:
    """List IAM roles in the AWS account."""
    try:
        aws = AWSClient()
        roles = aws.list_roles()
        
        # Filter to show relevant roles (not AWS service roles)
        relevant_roles = [r for r in roles if not r['name'].startswith('AWS')][:20]
        
        lines = [f"## IAM Roles ({len(relevant_roles)} shown)\n"]
        for role in relevant_roles:
            lines.append(f"- **{role['name']}**")
            if role['description']:
                lines.append(f"  - {role['description'][:80]}")
        
        return "\n".join(lines)
    except Exception as e:
        return _format_error(e)

@mcp.tool(name="aws_get_identity")
async def aws_get_identity() -> str:
    """Get the current AWS identity (who am I?)."""
    try:
        aws = AWSClient()
        identity = aws.get_caller_identity()
        
        return f"""## AWS Identity

- **Account:** {identity['account']}
- **ARN:** {identity['arn']}
- **User ID:** {identity['user_id']}
"""
    except Exception as e:
        return _format_error(e)

# =============================================================================
# TERRAFORM TOOLS
# =============================================================================

@mcp.tool(name="terraform_generate_eks")
async def terraform_generate_eks(params: CreateEKSClusterInput) -> str:
    """Generate Terraform configuration for a new EKS cluster."""
    try:
        tf = TerraformClient()
        
        # Generate VPC config
        vpc_config = tf.generate_vpc_config(f"{params.name}-vpc")
        
        # Generate EKS config
        eks_config = tf.generate_eks_cluster_config(
            cluster_name=params.name,
            environment=params.environment,
            node_count=params.node_count,
            instance_type=params.instance_type
        )
        
        return f"""## Generated Terraform Configuration

### VPC Configuration
`hcl
{vpc_config}
`

### EKS Cluster Configuration
`hcl
{eks_config}
`

### Next Steps
1. Save these configurations to your Terraform files
2. Run 	erraform plan to preview changes
3. Create a PR for review
4. After approval, run 	erraform apply
"""
    except Exception as e:
        return _format_error(e)

@mcp.tool(name="terraform_generate_iam_role")
async def terraform_generate_iam_role(role_name: str, policy: str = "ReadOnlyAccess") -> str:
    """Generate Terraform configuration for an IAM role."""
    try:
        tf = TerraformClient()
        
        policy_arn = f"arn:aws:iam::aws:policy/{policy}"
        config = tf.generate_iam_role_config(role_name, policy_arn)
        
        return f"""## Generated IAM Role Configuration
`hcl
{config}
`

**Policy:** {policy}
"""
    except Exception as e:
        return _format_error(e)

# =============================================================================
# COMPLIANCE & REPORTING TOOLS
# =============================================================================

@mcp.tool(name="generate_access_review")
async def generate_access_review(params: AccessReviewInput) -> str:
    """Generate a comprehensive access review report for compliance (SOC2, ISO27001)."""
    try:
        report = [
            "# Access Review Report",
            f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            f"**Scope:** {params.scope}",
            "---\n"
        ]
        
        # Okta Section
        if params.scope in ["all", "okta"]:
            report.append("## Okta Identity Summary\n")
            try:
                async with OktaClient() as client:
                    users = await client.list_users(limit=100)
                    groups = await client.list_groups(limit=50)
                    
                    active_users = [u for u in users if u.get('status') == 'ACTIVE']
                    inactive_users = [u for u in users if u.get('status') != 'ACTIVE']
                    
                    report.append(f"### Users")
                    report.append(f"- **Total:** {len(users)}")
                    report.append(f"- **Active:** {len(active_users)}")
                    report.append(f"- **Inactive/Suspended:** {len(inactive_users)}")
                    
                    if inactive_users:
                        report.append(f"\n**Inactive Users (Review Recommended):**")
                        for u in inactive_users[:10]:
                            p = u.get('profile', {})
                            report.append(f"- {p.get('email')} - Status: {u.get('status')}")
                    
                    report.append(f"\n### Groups")
                    report.append(f"- **Total:** {len(groups)}")
                    for g in groups[:10]:
                        p = g.get('profile', {})
                        report.append(f"- {p.get('name')}")
            except Exception as e:
                report.append(f"*Okta data unavailable: {e}*")
        
        # AWS Section
        if params.scope in ["all", "aws"]:
            report.append("\n## AWS Access Summary\n")
            try:
                aws = AWSClient()
                identity = aws.get_caller_identity()
                roles = aws.list_roles()
                
                report.append(f"### Account")
                report.append(f"- **Account ID:** {identity['account']}")
                
                report.append(f"\n### IAM Roles ({len(roles)} total)")
                admin_roles = [r for r in roles if 'admin' in r['name'].lower()]
                if admin_roles:
                    report.append(f"\n**Admin Roles (High Privilege):**")
                    for r in admin_roles:
                        report.append(f"- {r['name']}")
                
                # EKS Clusters
                clusters = aws.list_clusters()
                report.append(f"\n### EKS Clusters ({len(clusters)} total)")
                for c in clusters:
                    report.append(f"- {c}")
            except Exception as e:
                report.append(f"*AWS data unavailable: {e}*")
        
        report.append("\n---")
        report.append("## Recommendations")
        report.append("1. Review inactive Okta users and deactivate if no longer needed")
        report.append("2. Audit admin role assignments quarterly")
        report.append("3. Enable MFA for all privileged accounts")
        report.append("4. Review group memberships for least-privilege compliance")
        
        return "\n".join(report)
    except Exception as e:
        return _format_error(e)

@mcp.tool(name="check_user_access")
async def check_user_access(email: str) -> str:
    """Check all access for a specific user across Okta and AWS."""
    try:
        report = [f"# Access Report: {email}\n"]
        
        # Okta Access
        report.append("## Okta Access\n")
        try:
            async with OktaClient() as client:
                user = await client.get_user(email)
                groups = await client.list_groups()
                apps = await client.get_user_apps(user.get('id'))
                
                profile = user.get('profile', {})
                report.append(f"- **Name:** {profile.get('firstName')} {profile.get('lastName')}")
                report.append(f"- **Status:** {user.get('status')}")
                report.append(f"- **Department:** {profile.get('department', 'N/A')}")
                report.append(f"- **Title:** {profile.get('title', 'N/A')}")
                
                # Get user's groups
                user_groups = []
                for g in groups:
                    members = await client.get_group_members(g.get('id'))
                    if any(m.get('id') == user.get('id') for m in members):
                        user_groups.append(g.get('profile', {}).get('name'))
                
                report.append(f"\n### Groups ({len(user_groups)})")
                for g in user_groups:
                    report.append(f"- {g}")
                
                report.append(f"\n### Applications ({len(apps)})")
                for app in apps:
                    report.append(f"- {app.get('label', app.get('appName', 'Unknown'))}")
        except Exception as e:
            report.append(f"*Okta data unavailable: {e}*")
        
        return "\n".join(report)
    except Exception as e:
        return _format_error(e)

# =============================================================================
# PIPELINE TOOLS
# =============================================================================

@mcp.tool(name="create_infrastructure_pr")
async def create_infrastructure_pr(params: CreatePRInput) -> str:
    """Create a Pull Request with infrastructure changes."""
    try:
        gh = GitHubClient()
        
        # Create branch
        gh.create_branch(params.branch_name)
        
        # Create/update files
        for filepath, content in params.files.items():
            gh.create_file(
                path=filepath,
                content=content,
                message=f"Add {filepath}",
                branch=params.branch_name
            )
        
        # Create PR
        result = gh.create_pull_request(
            title=params.title,
            body=params.description,
            head_branch=params.branch_name
        )
        
        return f"""## Pull Request Created!

- **Title:** {params.title}
- **PR Number:** #{result['pr_number']}
- **URL:** {result['url']}

The CI/CD pipeline will automatically:
1. Run 	erraform fmt and 	erraform validate
2. Generate a 	erraform plan
3. Post the plan as a comment
4. Run security scans

Once approved and merged, changes will be applied to dev, then prod.
"""
    except Exception as e:
        return _format_error(e)

@mcp.tool(name="list_open_prs")
async def list_open_prs() -> str:
    """List open Pull Requests in the infrastructure repository."""
    try:
        gh = GitHubClient()
        prs = gh.list_pull_requests(state="open")
        
        if not prs:
            return "No open Pull Requests."
        
        lines = [f"## Open Pull Requests ({len(prs)})\n"]
        for pr in prs:
            lines.append(f"### #{pr['number']}: {pr['title']}")
            lines.append(f"- **Author:** {pr['author']}")
            lines.append(f"- **Created:** {pr['created_at']}")
            lines.append(f"- **URL:** {pr['url']}")
            lines.append("")
        
        return "\n".join(lines)
    except Exception as e:
        return _format_error(e)

@mcp.tool(name="list_pipeline_runs")
async def list_pipeline_runs(limit: int = 5) -> str:
    """List recent CI/CD pipeline runs."""
    try:
        gh = GitHubClient()
        runs = gh.list_workflow_runs(limit=limit)
        
        if not runs:
            return "No recent workflow runs."
        
        lines = ["## Recent Pipeline Runs\n"]
        for run in runs:
            status_emoji = "" if run['conclusion'] == 'success' else "" if run['conclusion'] == 'failure' else ""
            lines.append(f"- {status_emoji} **{run['name']}** on {run['branch']}")
            lines.append(f"  - Status: {run['status']} | Conclusion: {run['conclusion'] or 'in progress'}")
            lines.append(f"  - [View Run]({run['url']})")
        
        return "\n".join(lines)
    except Exception as e:
        return _format_error(e)

# =============================================================================
# MAIN
# =============================================================================

def main():
    print("Starting Infrastructure Automation MCP Server...", file=sys.stderr)
    mcp.run()

if __name__ == "__main__":
    main()