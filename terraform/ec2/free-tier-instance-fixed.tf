# =============================================================================
# EC2 Instance - Free Tier Eligible (Fixed - Uses Default VPC)
# =============================================================================

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

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
resource "aws_security_group" "free_tier_instance_sg" {
  name        = "free-tier-instance-sg"
  description = "Security group for free-tier-instance"
  vpc_id      = data.aws_vpc.default.id

  # SSH access (restrict to your IP in production!)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # TODO: Restrict to your IP
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

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "free-tier-instance-sg"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# EC2 Instance - t2.micro is free tier eligible
resource "aws_instance" "free_tier_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"  # Free tier eligible!
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = [aws_security_group.free_tier_instance_sg.id]
  
  associate_public_ip_address = true

  root_block_device {
    volume_size = 8    # GB - Free tier includes 30GB total
    volume_type = "gp2"
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Free Tier EC2 Instance - Running!</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name        = "free-tier-instance"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "free_tier_instance_public_ip" {
  value       = aws_instance.free_tier_instance.public_ip
  description = "Public IP of free-tier-instance"
}

output "free_tier_instance_instance_id" {
  value       = aws_instance.free_tier_instance.id
  description = "Instance ID of free-tier-instance"
}

output "free_tier_instance_public_dns" {
  value       = aws_instance.free_tier_instance.public_dns
  description = "Public DNS of free-tier-instance"
}

output "instance_url" {
  value       = "http://${aws_instance.free_tier_instance.public_ip}"
  description = "URL to access the web server"
}