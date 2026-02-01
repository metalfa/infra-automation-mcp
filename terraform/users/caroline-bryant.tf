# =============================================================================
# Caroline Bryant - IT System Engineer
# Onboarded: 2026-02-01
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
resource "aws_security_group" "caroline_bryant_dev_box_sg" {
  name        = "caroline-bryant-dev-box-sg"
  description = "Security group for caroline-bryant-dev-box"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Internal network only
    description = "SSH access from internal network"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "caroline-bryant-dev-box-sg"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "caroline.bryant@demoaactivec.com"
  }
}

# EC2 Instance - t2.micro is free tier eligible
resource "aws_instance" "caroline_bryant_dev_box" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.caroline_bryant_dev_box_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.caroline_bryant_profile.name

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
    encrypted   = true
  }

  tags = {
    Name        = "caroline-bryant-dev-box"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "caroline.bryant@demoaactivec.com"
  }
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "caroline_bryant_profile" {
  name = "caroline-bryant-instance-profile"
  role = aws_iam_role.caroline_bryant_ec2_role.name
}

resource "aws_iam_role" "caroline_bryant_ec2_role" {
  name = "caroline-bryant-ec2-role"

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
    ManagedBy = "terraform"
    Owner     = "caroline.bryant@demoaactivec.com"
  }
}

# Outputs
output "caroline_bryant_dev_box_public_ip" {
  value       = aws_instance.caroline_bryant_dev_box.public_ip
  description = "Public IP of caroline-bryant-dev-box"
}

output "caroline_bryant_dev_box_instance_id" {
  value       = aws_instance.caroline_bryant_dev_box.id
  description = "Instance ID of caroline-bryant-dev-box"
}