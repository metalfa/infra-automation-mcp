# =============================================================================
# EC2 Instance - Free Tier Eligible
# Carlos Santana - Red Security Team
# =============================================================================

# Get the latest Amazon Linux 2 AMI (free tier eligible)
data "aws_ami" "amazon_linux_2_carlos_santana" {
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
resource "aws_security_group" "carlos_santana_development_box_sg" {
  name        = "carlos-santana-development-box-sg"
  description = "Security group for carlos-santana-development-box"
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
    Name        = "carlos-santana-development-box-sg"
    Environment = "dev"
    Team        = "Red Security"
    ManagedBy   = "terraform"
  }
}

# EC2 Instance - t2.micro is free tier eligible
resource "aws_instance" "carlos_santana_development_box" {
  ami                    = data.aws_ami.amazon_linux_2_carlos_santana.id
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.carlos_santana_development_box_sg.id]
  
  root_block_device {
    volume_size = 8
    volume_type = "gp2"
    encrypted   = true
  }

  tags = {
    Name        = "carlos-santana-development-box"
    Environment = "dev"
    Owner       = "carlos.santana@demoaactivec.com"
    Team        = "Red Security"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "carlos_santana_development_box_public_ip" {
  value       = aws_instance.carlos_santana_development_box.public_ip
  description = "Public IP of carlos-santana-development-box"
}

output "carlos_santana_development_box_instance_id" {
  value       = aws_instance.carlos_santana_development_box.id
  description = "Instance ID of carlos-santana-development-box"
}