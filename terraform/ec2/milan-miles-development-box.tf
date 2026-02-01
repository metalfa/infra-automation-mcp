# =============================================================================
# EC2 Instance - Free Tier Eligible
# Onboarding: Milan Miles (Security Engineer)
# =============================================================================

# Get the latest Amazon Linux 2 AMI (free tier eligible)
data "aws_ami" "amazon_linux_2_milan_miles" {
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
resource "aws_security_group" "milan_miles_development_box_sg" {
  name        = "milan-miles-development-box-sg"
  description = "Security group for milan-miles-development-box"
  vpc_id      = module.vpc.vpc_id

  # SSH access (restrict to your IP in production!)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Internal network only
    description = "SSH access from internal network"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "milan-miles-development-box-sg"
    Environment = "dev"
    Owner       = "milan.miles@demoaactivec.com"
    ManagedBy   = "terraform"
  }
}

# EC2 Instance - t2.micro is free tier eligible
resource "aws_instance" "milan_miles_development_box" {
  ami                    = data.aws_ami.amazon_linux_2_milan_miles.id
  instance_type          = "t2.micro"  # Free tier eligible!
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.milan_miles_development_box_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.milan_miles_profile.name

  root_block_device {
    volume_size = 8    # GB - Free tier includes 30GB total
    volume_type = "gp2"
    encrypted   = true
  }

  tags = {
    Name        = "milan-miles-development-box"
    Environment = "dev"
    Owner       = "milan.miles@demoaactivec.com"
    Team        = "Security Engineering"
    ManagedBy   = "terraform"
  }
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "milan_miles_profile" {
  name = "milan-miles-ec2-profile"
  role = aws_iam_role.milan_miles_ec2_role.name
}

resource "aws_iam_role" "milan_miles_ec2_role" {
  name = "milan-miles-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Owner     = "milan.miles@demoaactivec.com"
    ManagedBy = "terraform"
  }
}

# Outputs
output "milan_miles_development_box_public_ip" {
  value       = aws_instance.milan_miles_development_box.public_ip
  description = "Public IP of milan-miles-development-box"
}

output "milan_miles_development_box_instance_id" {
  value       = aws_instance.milan_miles_development_box.id
  description = "Instance ID of milan-miles-development-box"
}