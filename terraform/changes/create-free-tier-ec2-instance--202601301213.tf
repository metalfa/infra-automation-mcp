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
resource "aws_security_group" "my_free_ec2_instance_sg" {
  name        = "my-free-ec2-instance-sg"
  description = "Security group for my-free-ec2-instance"

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
    Name        = "my-free-ec2-instance-sg"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# EC2 Instance - t2.micro is free tier eligible
resource "aws_instance" "my_free_ec2_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"  # Free tier eligible!
  vpc_security_group_ids = [aws_security_group.my_free_ec2_instance_sg.id]
  
  root_block_device {
    volume_size = 8    # GB - Free tier includes 30GB total
    volume_type = "gp2"
    encrypted   = true
  }

  tags = {
    Name        = "my-free-ec2-instance"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "my_free_ec2_instance_public_ip" {
  value       = aws_instance.my_free_ec2_instance.public_ip
  description = "Public IP of my-free-ec2-instance"
}

output "my_free_ec2_instance_instance_id" {
  value       = aws_instance.my_free_ec2_instance.id
  description = "Instance ID of my-free-ec2-instance"
}