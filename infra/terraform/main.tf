# Simple Terraform configuration for AWS Infrastructure - Study Environment
# Replace the variable values in terraform.tfvars or through CLI
# Make sure to configure AWS credentials before running terraform commands

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Data source for Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Use default VPC (simpler approach)
data "aws_vpc" "default" {
  default = true
}

# Get default subnet
data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = data.aws_availability_zones.available.names[0]
  default_for_az    = true
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create simple security group
resource "aws_security_group" "study_sg" {
  name_prefix = "study-sg"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open for study - not recommended for production
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins web interface
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "study-security-group"
  }
}

# Simple IAM role for EC2 instance (optional)
resource "aws_iam_role" "study_role" {
  name = "study-ec2-role"

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
    Name = "study-ec2-role"
  }
}

# Attach basic EC2 role policy
resource "aws_iam_role_policy_attachment" "study_policy_attachment" {
  role       = aws_iam_role.study_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create instance profile
resource "aws_iam_instance_profile" "study_profile" {
  name = "study-instance-profile"
  role = aws_iam_role.study_role.name
}

# Simple user data script
locals {
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    
    # Install basic tools
    yum install -y git wget curl
    
    # Create a simple status file
    echo "EC2 instance setup completed at $(date)" > /home/ec2-user/setup-status.txt
    chown ec2-user:ec2-user /home/ec2-user/setup-status.txt
  EOF
}

# Simple EC2 instance - Free Tier Compatible
resource "aws_instance" "study_server" {
  ami                    = data.aws_ami.amazon_linux.id  # Free tier eligible
  instance_type          = var.instance_type             # t3.micro (default) - free tier
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.study_sg.id]
  subnet_id              = data.aws_subnet.default.id
  iam_instance_profile   = aws_iam_instance_profile.study_profile.name

  user_data = base64encode(local.user_data)

  # No custom EBS volume specified = uses default 8GB (within free tier 30GB limit)

  tags = {
    Name = "study-server"
  }
}

# This is a simplified setup for study purposes
# No additional complex resources to reduce chances of failure