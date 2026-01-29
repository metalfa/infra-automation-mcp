# =============================================================================
# EC2 Instance - Free Tier Eligible
# =============================================================================

# Get the latest Amazon Linux 2 AMI (free tier eligible)
data "aws_ami" "amazon_linux_2" {
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
resource "aws_security_group" "dev_workstation_alex_sg" {
  name        = "dev-workstation-alex-sg"
  description = "Security group for dev-workstation-alex"
  vpc_id      = module.vpc.vpc_id

  # SSH access (restrict to your IP in production!)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # TODO: Restrict to your IP
    description = "SSH access"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "dev-workstation-alex-sg"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# EC2 Instance - t2.micro is free tier eligible
resource "aws_instance" "dev_workstation_alex" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"  # Free tier eligible!
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.dev_workstation_alex_sg.id]
  
  # Enable if you need SSH access
  # key_name = "your-key-pair-name"

  root_block_device {
    volume_size = 8    # GB - Free tier includes 30GB total
    volume_type = "gp2"
    encrypted   = true
  }

  tags = {
    Name        = "dev-workstation-alex"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "dev_workstation_alex_public_ip" {
  value       = aws_instance.dev_workstation_alex.public_ip
  description = "Public IP of dev-workstation-alex"
}

output "dev_workstation_alex_instance_id" {
  value       = aws_instance.dev_workstation_alex.id
  description = "Instance ID of dev-workstation-alex"
}