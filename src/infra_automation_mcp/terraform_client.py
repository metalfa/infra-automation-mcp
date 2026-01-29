"""Terraform Operations Client - Generate, Plan, and Apply Infrastructure"""

import os
import json
import subprocess
import tempfile
from typing import Optional
from pathlib import Path


class TerraformError(Exception):
    def __init__(self, message: str, output: str = None):
        self.message = message
        self.output = output
        super().__init__(self.message)


class TerraformClient:
    """Client for Terraform operations - generates configs and runs commands."""
    
    def __init__(self, working_dir: str = None):
        self.working_dir = working_dir or os.getenv("TERRAFORM_WORKING_DIR", tempfile.mkdtemp())
        Path(self.working_dir).mkdir(parents=True, exist_ok=True)
    
    def _run_command(self, args: list, capture_output: bool = True) -> tuple[int, str, str]:
        """Run a terraform command and return (returncode, stdout, stderr)."""
        try:
            result = subprocess.run(
                ["terraform"] + args,
                cwd=self.working_dir,
                capture_output=capture_output,
                text=True,
                timeout=300  # 5 minute timeout
            )
            return result.returncode, result.stdout, result.stderr
        except FileNotFoundError:
            raise TerraformError("Terraform CLI not found. Please install Terraform.")
        except subprocess.TimeoutExpired:
            raise TerraformError("Terraform command timed out")

    def generate_okta_user_config(self, email: str, first_name: str, last_name: str,
                                   department: str = None, groups: list = None) -> str:
        """Generate Terraform config for an Okta user."""
        resource_name = email.replace("@", "_").replace(".", "_")
        
        config = f'''
# Okta User: {first_name} {last_name}
resource "okta_user" "{resource_name}" {{
  first_name = "{first_name}"
  last_name  = "{last_name}"
  email      = "{email}"
  login      = "{email}"
'''
        if department:
            config += f'  department = "{department}"\n'
        config += "}\n"
        
        # Add group memberships
        if groups:
            for group in groups:
                group_resource = group.lower().replace("-", "_").replace(" ", "_")
                config += f'''
resource "okta_group_membership" "{resource_name}_{group_resource}" {{
  group_id = okta_group.{group_resource}.id
  user_id  = okta_user.{resource_name}.id
}}
'''
        return config

    def generate_okta_group_config(self, name: str, description: str = None) -> str:
        """Generate Terraform config for an Okta group."""
        resource_name = name.lower().replace("-", "_").replace(" ", "_")
        return f'''
# Okta Group: {name}
resource "okta_group" "{resource_name}" {{
  name        = "{name}"
  description = "{description or name}"
}}
'''

    def generate_eks_cluster_config(self, cluster_name: str, environment: str,
                                     node_count: int = 2, instance_type: str = "t3.medium") -> str:
        """Generate Terraform config for an EKS cluster."""
        return f'''
# EKS Cluster: {cluster_name}
module "eks_{cluster_name.replace("-", "_")}" {{
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "{cluster_name}"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {{
    general = {{
      name           = "general-{environment}"
      instance_types = ["{instance_type}"]
      min_size       = 1
      max_size       = {node_count * 2}
      desired_size   = {node_count}

      labels = {{
        Environment = "{environment}"
      }}
    }}
  }}

  tags = {{
    Environment = "{environment}"
    ManagedBy   = "terraform"
    Cluster     = "{cluster_name}"
  }}
}}

output "{cluster_name.replace("-", "_")}_endpoint" {{
  value = module.eks_{cluster_name.replace("-", "_")}.cluster_endpoint
}}
'''

    def generate_vpc_config(self, name: str, cidr: str = "10.0.0.0/16", azs: int = 2) -> str:
        """Generate Terraform config for a VPC."""
        private_subnets = ", ".join([f'"10.0.{i+1}.0/24"' for i in range(azs)])
        public_subnets = ", ".join([f'"10.0.{i+101}.0/24"' for i in range(azs)])
        az_list = ", ".join([f'"us-east-1{chr(97+i)}"' for i in range(azs)])
        
        return f'''
# VPC: {name}
module "vpc" {{
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "{name}"
  cidr = "{cidr}"

  azs             = [{az_list}]
  private_subnets = [{private_subnets}]
  public_subnets  = [{public_subnets}]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {{
    ManagedBy = "terraform"
  }}
}}
'''

    def generate_iam_role_config(self, role_name: str, policy_arn: str, 
                                  trust_principal: str = "ec2.amazonaws.com") -> str:
        """Generate Terraform config for an IAM role."""
        resource_name = role_name.lower().replace("-", "_")
        return f'''
# IAM Role: {role_name}
resource "aws_iam_role" "{resource_name}" {{
  name = "{role_name}"

  assume_role_policy = jsonencode({{
    Version = "2012-10-17"
    Statement = [{{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {{
        Service = "{trust_principal}"
      }}
    }}]
  }})
}}

resource "aws_iam_role_policy_attachment" "{resource_name}_policy" {{
  role       = aws_iam_role.{resource_name}.name
  policy_arn = "{policy_arn}"
}}
'''

    def write_config(self, filename: str, content: str) -> str:
        """Write Terraform config to a file."""
        filepath = os.path.join(self.working_dir, filename)
        with open(filepath, "w") as f:
            f.write(content)
        return filepath

    def init(self) -> tuple[bool, str]:
        """Run terraform init."""
        code, stdout, stderr = self._run_command(["init", "-no-color"])
        output = stdout + stderr
        return code == 0, output

    def plan(self, out_file: str = "tfplan") -> tuple[bool, str]:
        """Run terraform plan."""
        code, stdout, stderr = self._run_command(["plan", "-no-color", f"-out={out_file}"])
        output = stdout + stderr
        return code == 0, output

    def apply(self, auto_approve: bool = False) -> tuple[bool, str]:
        """Run terraform apply."""
        args = ["apply", "-no-color"]
        if auto_approve:
            args.append("-auto-approve")
        code, stdout, stderr = self._run_command(args)
        output = stdout + stderr
        return code == 0, output

    def show_state(self) -> tuple[bool, str]:
        """Run terraform show to display current state."""
        code, stdout, stderr = self._run_command(["show", "-no-color"])
        output = stdout + stderr
        return code == 0, output

    def output(self) -> tuple[bool, dict]:
        """Get terraform outputs as JSON."""
        code, stdout, stderr = self._run_command(["output", "-json"])
        if code == 0:
            try:
                return True, json.loads(stdout)
            except json.JSONDecodeError:
                return False, {}
        return False, {}

    def fmt(self) -> tuple[bool, str]:
        """Run terraform fmt to format files."""
        code, stdout, stderr = self._run_command(["fmt", "-recursive"])
        return code == 0, stdout + stderr

    def validate(self) -> tuple[bool, str]:
        """Run terraform validate."""
        code, stdout, stderr = self._run_command(["validate", "-no-color"])
        return code == 0, stdout + stderr