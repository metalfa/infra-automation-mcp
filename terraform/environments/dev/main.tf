# =============================================================================
# Terraform Configuration - Auto-Deploy Demo
# =============================================================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Store state in S3 (we'll create this bucket manually first)
  backend "s3" {
    bucket         = "infra-automation-tfstate-activecampaign-demo"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment   = var.environment
      ManagedBy     = "terraform"
      Project       = "infra-automation-mcp"
      AutoDestroy   = "true"
      CreatedBy     = "github-actions"
    }
  }
}

# =============================================================================
# Variables
# =============================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "instance_name" {
  description = "Name for the EC2 instance"
  type        = string
  default     = "mcp-demo-instance"
}

# =============================================================================
# Data Sources
# =============================================================================

# Get latest Amazon Linux 2023 AMI (free tier eligible)
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

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# =============================================================================
# Security Group
# =============================================================================

resource "aws_security_group" "demo" {
  name        = "${var.instance_name}-sg"
  description = "Security group for MCP demo instance"
  vpc_id      = data.aws_vpc.default.id

  # SSH access (for demo only - restrict in production!)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

# =============================================================================
# EC2 Instance - Free Tier (t2.micro)
# =============================================================================

resource "aws_instance" "demo" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"  # Free tier eligible!
  vpc_security_group_ids = [aws_security_group.demo.id]

  # Simple web server for demo
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              cat > /var/www/html/index.html << 'HTMLEOF'
              <!DOCTYPE html>
              <html>
              <head>
                  <title>Infrastructure Automation Demo</title>
                  <style>
                      body {
                          font-family: Arial, sans-serif;
                          max-width: 800px;
                          margin: 50px auto;
                          padding: 20px;
                          background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
                          color: white;
                          min-height: 100vh;
                      }
                      h1 { color: #00d4ff; }
                      .box {
                          background: rgba(255,255,255,0.1);
                          padding: 20px;
                          border-radius: 10px;
                          margin: 20px 0;
                      }
                      .success { color: #00ff88; }
                      .warning { color: #ffcc00; }
                  </style>
              </head>
              <body>
                  <h1>🚀 Infrastructure Automation MCP</h1>
                  
                  <div class="box">
                      <h2 class="success">✅ EC2 Instance Deployed Successfully!</h2>
                      <p>This instance was created automatically by:</p>
                      <ul>
                          <li>Natural language request to Claude</li>
                          <li>MCP generated Terraform configuration</li>
                          <li>GitHub Actions CI/CD pipeline</li>
                      </ul>
                  </div>
                  
                  <div class="box">
                      <h2>📋 Demo Details</h2>
                      <p><strong>Instance Type:</strong> t2.micro (Free Tier)</p>
                      <p><strong>Created By:</strong> Faycal Ben Sassi</p>
                      <p><strong>Purpose:</strong> ActiveCampaign Interview Demo</p>
                  </div>
                  
                  <div class="box">
                      <h2 class="warning">⏰ Auto-Destroy Notice</h2>
                      <p>This instance will be automatically destroyed in <strong>3 minutes</strong> to avoid AWS charges.</p>
                  </div>
                  
                  <div class="box">
                      <h2>🔗 Project Links</h2>
                      <p><a href="https://github.com/metalfa/infra-automation-mcp" style="color: #00d4ff;">GitHub Repository</a></p>
                  </div>
                  
                  <p style="text-align: center; margin-top: 40px;">
                      <em>"The future of DevOps is conversational"</em>
                  </p>
              </body>
              </html>
              HTMLEOF
              EOF

  tags = {
    Name        = var.instance_name
    AutoDestroy = "true"
  }
}

# =============================================================================
# IAM Role (for demo)
# =============================================================================

resource "aws_iam_role" "demo" {
  name = "${var.instance_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.instance_name}-role"
  }
}

resource "aws_iam_role_policy_attachment" "demo" {
  role       = aws_iam_role.demo.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "demo" {
  name = "${var.instance_name}-profile"
  role = aws_iam_role.demo.name
}

# =============================================================================
# Outputs
# =============================================================================

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.demo.id
}

output "instance_public_ip" {
  description = "Public IP address"
  value       = aws_instance.demo.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name"
  value       = aws_instance.demo.public_dns
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.demo.id
}

output "iam_role_arn" {
  description = "IAM Role ARN"
  value       = aws_iam_role.demo.arn
}

output "web_url" {
  description = "URL to access the web server"
  value       = "http://${aws_instance.demo.public_ip}"
}