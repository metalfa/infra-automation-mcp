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
              echo "<html><body><h1>Hello from MCP Auto-Deploy!</h1><p>Instance: ${var.instance_name}</p><p>Created by: Infrastructure Automation MCP</p><p>This instance will auto-destroy in 3 minutes.</p></body></html>" > /var/www/html/index.html
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