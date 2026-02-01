# =============================================================================
# IAM Configuration for Emmy Bentley
# Integrated with Okta SSO
# =============================================================================

# IAM Group (maps to Okta group: IT System Engineering)
resource "aws_iam_group" "it_system_engineering" {
  name = "it-system-engineering"
  path = "/users/"
}

# IAM Group Policy - PowerUser Access for IT System Engineers
resource "aws_iam_group_policy_attachment" "it_system_engineering_policy" {
  group      = aws_iam_group.it_system_engineering.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# IAM User
resource "aws_iam_user" "emmy_bentley" {
  name = "emmy.bentley"
  path = "/users/"

  tags = {
    OktaGroup   = "IT System Engineering"
    Email       = "emmy.bentley@demoaactivec.com"
    ManagedBy   = "terraform"
    Description = "User synced from Okta"
  }
}

# Add user to group
resource "aws_iam_user_group_membership" "emmy_bentley_membership" {
  user   = aws_iam_user.emmy_bentley.name
  groups = [aws_iam_group.it_system_engineering.name]
}

# IAM Role for EC2 instance
resource "aws_iam_role" "emmy_bentley_ec2_role" {
  name = "emmy-bentley-ec2-role"

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
    Owner     = "emmy.bentley@demoaactivec.com"
    ManagedBy = "terraform"
  }
}

# Attach SSM policy for Session Manager access
resource "aws_iam_role_policy_attachment" "emmy_bentley_ssm" {
  role       = aws_iam_role.emmy_bentley_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile
resource "aws_iam_instance_profile" "emmy_bentley_profile" {
  name = "emmy-bentley-ec2-profile"
  role = aws_iam_role.emmy_bentley_ec2_role.name
}
