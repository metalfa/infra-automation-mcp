# =============================================================================
# EC2 Instance - Emmy Bentley Development Box
# Free Tier Eligible
# =============================================================================

# Get the latest Amazon Linux 2 AMI (free tier eligible)
data "aws_ami" "amazon_linux_2_emmy" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for the EC2 instance
resource "aws_security_group" "emmy_bentley_development_box_sg" {
  name        = "emmy-bentley-development-box-sg"
  description = "Security group for emmy-bentley-development-box"
  vpc_id      = module.vpc.vpc_id

  # SSH access (restricted to VPN)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpn_cidr]
    description = "SSH access via VPN"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "emmy-bentley-development-box-sg"
    Environment = "dev"
    Owner       = "emmy.bentley@demoaactivec.com"
    ManagedBy   = "terraform"
  }
}

# EC2 Instance - t2.micro is free tier eligible
resource "aws_instance" "emmy_bentley_development_box" {
  ami                    = data.aws_ami.amazon_linux_2_emmy.id
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.emmy_bentley_development_box_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.emmy_bentley_profile.name

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
    encrypted   = true
  }

  tags = {
    Name        = "emmy-bentley-development-box"
    Environment = "dev"
    Owner       = "emmy.bentley@demoaactivec.com"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "emmy_bentley_development_box_public_ip" {
  value       = aws_instance.emmy_bentley_development_box.public_ip
  description = "Public IP of emmy-bentley-development-box"
}

output "emmy_bentley_development_box_instance_id" {
  value       = aws_instance.emmy_bentley_development_box.id
  description = "Instance ID of emmy-bentley-development-box"
}
