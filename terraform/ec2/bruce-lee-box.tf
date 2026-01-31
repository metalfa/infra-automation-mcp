# =============================================================================
# EC2 Instance - Free Tier Eligible
# Security Engineer: Bruce Lee
# =============================================================================

# Get the latest Amazon Linux 2 AMI (free tier eligible)
data "aws_ami" "amazon_linux_2_bruce" {
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
resource "aws_security_group" "bruce_lee_box_sg" {
  name        = "bruce-lee-box-sg"
  description = "Security group for bruce-lee-box"
  vpc_id      = module.vpc.vpc_id

  # SSH access (restrict to your IP in production!)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # TODO: Restrict to office IP range
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
    Name        = "bruce-lee-box-sg"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "bruce.lee"
    Team        = "Security"
  }
}

# EC2 Instance - t2.micro is free tier eligible
resource "aws_instance" "bruce_lee_box" {
  ami                    = data.aws_ami.amazon_linux_2_bruce.id
  instance_type          = "t2.micro"  # Free tier eligible!
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bruce_lee_box_sg.id]
  
  # Enable if you need SSH access
  # key_name = "your-key-pair-name"

  root_block_device {
    volume_size = 8    # GB - Free tier includes 30GB total
    volume_type = "gp2"
    encrypted   = true
  }

  tags = {
    Name        = "bruce-lee-box"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "bruce.lee"
    Team        = "Security"
  }
}

# Outputs
output "bruce_lee_box_public_ip" {
  value       = aws_instance.bruce_lee_box.public_ip
  description = "Public IP of bruce-lee-box"
}

output "bruce_lee_box_instance_id" {
  value       = aws_instance.bruce_lee_box.id
  description = "Instance ID of bruce-lee-box"
}