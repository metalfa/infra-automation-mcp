# =============================================================================
# Terraform Configuration - SAML-Ready Federation Setup
# =============================================================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "infra-automation-tfstate-activecampaign-demo"
    key     = "dev/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "terraform"
      Project     = "infra-automation-mcp"
    }
  }
}

# =============================================================================
# SECTION 1: IAM Groups (Okta Group Mapping)
# =============================================================================

# Platform Engineers Group
resource "aws_iam_group" "platform_engineers" {
  name = "platform-engineers"
  path = "/okta-synced/"
}

resource "aws_iam_group_policy_attachment" "platform_engineers_power" {
  group      = aws_iam_group.platform_engineers.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Developers Group
resource "aws_iam_group" "developers" {
  name = "developers"
  path = "/okta-synced/"
}

resource "aws_iam_group_policy_attachment" "developers_ec2" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_group_policy_attachment" "developers_s3" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# ReadOnly Group (Auditors)
resource "aws_iam_group" "readonly" {
  name = "readonly-users"
  path = "/okta-synced/"
}

resource "aws_iam_group_policy_attachment" "readonly_policy" {
  group      = aws_iam_group.readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# =============================================================================
# SECTION 2: Demo IAM Users (Linked to Okta via Tags)
# =============================================================================

resource "aws_iam_user" "demo_platform_engineer" {
  name = "demo-platform-engineer"
  path = "/okta-synced/"
  
  tags = {
    OktaGroup       = "okta-platform-engineers"
    OktaEmail       = "engineer@demo.com"
    SAMLFederated   = "true"
    Description     = "Demo user - would be auto-provisioned via Okta SCIM in production"
  }
}

resource "aws_iam_user_group_membership" "demo_platform_engineer" {
  user   = aws_iam_user.demo_platform_engineer.name
  groups = [aws_iam_group.platform_engineers.name]
}

resource "aws_iam_user" "demo_developer" {
  name = "demo-developer"
  path = "/okta-synced/"
  
  tags = {
    OktaGroup       = "okta-developers"
    OktaEmail       = "developer@demo.com"
    SAMLFederated   = "true"
    Description     = "Demo user - would be auto-provisioned via Okta SCIM in production"
  }
}

resource "aws_iam_user_group_membership" "demo_developer" {
  user   = aws_iam_user.demo_developer.name
  groups = [aws_iam_group.developers.name]
}

# =============================================================================
# SECTION 3: SAML-Ready IAM Roles (For Full SSO)
# =============================================================================

# These roles are ready for SAML federation
# Just need to update the trust policy with actual Okta SAML provider ARN

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "okta_platform_engineers_sso" {
  name        = "Okta-SSO-PlatformEngineers"
  description = "SAML federated role for Platform Engineers"
  
  # Trust policy template - ready for SAML provider
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # In production, replace with: Federated = aws_iam_saml_provider.okta.arn
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/OktaGroup" = "okta-platform-engineers"
          }
        }
      }
    ]
  })

  max_session_duration = 43200

  tags = {
    OktaGroup     = "okta-platform-engineers"
    SAMLReady     = "true"
    AccessLevel   = "PowerUser"
  }
}

resource "aws_iam_role_policy_attachment" "okta_platform_engineers_policy" {
  role       = aws_iam_role.okta_platform_engineers_sso.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_role" "okta_developers_sso" {
  name        = "Okta-SSO-Developers"
  description = "SAML federated role for Developers"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/OktaGroup" = "okta-developers"
          }
        }
      }
    ]
  })

  max_session_duration = 28800

  tags = {
    OktaGroup     = "okta-developers"
    SAMLReady     = "true"
    AccessLevel   = "Developer"
  }
}

resource "aws_iam_role_policy_attachment" "okta_developers_ec2" {
  role       = aws_iam_role.okta_developers_sso.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# =============================================================================
# SECTION 4: EC2 Demo Instance
# =============================================================================

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "demo" {
  name        = "mcp-demo-sg"
  description = "Security group for MCP demo"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mcp-demo-sg"
  }
}

resource "aws_instance" "demo" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.demo.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>MCP Demo - EC2 + IAM + Okta SSO Ready</h1><p>Auto-destroy in 3 min</p>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "mcp-demo-instance"
  }
}

# =============================================================================
# SECTION 5: Outputs
# =============================================================================

output "instance_public_ip" {
  value = aws_instance.demo.public_ip
}

output "iam_groups" {
  value = {
    platform_engineers = aws_iam_group.platform_engineers.name
    developers         = aws_iam_group.developers.name
    readonly           = aws_iam_group.readonly.name
  }
}

output "iam_users" {
  value = {
    platform_engineer = aws_iam_user.demo_platform_engineer.name
    developer         = aws_iam_user.demo_developer.name
  }
}

output "sso_roles" {
  value = {
    platform_engineers = aws_iam_role.okta_platform_engineers_sso.arn
    developers         = aws_iam_role.okta_developers_sso.arn
  }
}

output "okta_mapping" {
  value = <<-EOT
    
    Okta Group → AWS IAM Group → AWS IAM Role
    ═══════════════════════════════════════════
    okta-platform-engineers → platform-engineers → Okta-SSO-PlatformEngineers
    okta-developers         → developers         → Okta-SSO-Developers
    okta-readonly           → readonly-users     → (ReadOnly access)
    
  EOT
}