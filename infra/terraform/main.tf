# This is a simplified setup for study purposes
# No additional complex resources to reduce chances of failure
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

# Enhanced user data script for Ansible compatibility
locals {
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    
    # Install Python 3 and pip (required for Ansible)
    yum install -y python3 python3-pip python3-devel
    
    # Install basic tools and dependencies
    yum install -y git wget curl unzip vim
    
    # Install development tools for compiling Python packages
    yum groupinstall -y "Development Tools"
    
    # Install OpenSSL development headers (needed for some Python packages)
    yum install -y openssl-devel libffi-devel
    
    # Ensure pip is up to date
    python3 -m pip install --upgrade pip
    
    # Install some common Python packages that Ansible might need
    python3 -m pip install setuptools wheel
    
    # Create a simple status file
    echo "EC2 instance setup completed at $(date)" > /home/ec2-user/setup-status.txt
    echo "Python version: $(python3 --version)" >> /home/ec2-user/setup-status.txt
    echo "Pip version: $(python3 -m pip --version)" >> /home/ec2-user/setup-status.txt
    chown ec2-user:ec2-user /home/ec2-user/setup-status.txt
    
    # Set Python3 as default python for ec2-user
    echo 'alias python=python3' >> /home/ec2-user/.bashrc
    echo 'alias pip=pip3' >> /home/ec2-user/.bashrc
  EOF
}

# Simple EC2 instance - Free Tier Compatible
resource "aws_instance" "jenkins_server" {
  ami           = "ami-0453ec754f44f9a4a"  # Amazon Linux 2023 AMI
  instance_type = "t3.small"
  key_name      = "yasinkey"

  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    
    # Update system
    dnf update -y
    
    # Install essential packages for Ansible compatibility
    dnf install -y git curl wget python3.11 python3.11-pip python3.11-devel
    
    # Install development tools needed for Python packages  
    dnf groupinstall -y "Development Tools"
    dnf install -y openssl-devel libffi-devel bzip2-devel
    
    # Create symlinks for python3 and pip3 to use Python 3.11
    alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
    alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.11 1
    
    # Ensure pip is up to date
    python3 -m pip install --upgrade pip
    
    # Install essential Python packages
    python3 -m pip install setuptools wheel
    
    # Create directory for later use
    mkdir -p /home/ec2-user/workspace
    chown ec2-user:ec2-user /home/ec2-user/workspace
    
    # Enable SSH access
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
    
    echo "System initialization complete with Python 3.11"
  EOF
  )

  tags = {
    Name = "VLE7-Jenkins-Server"
  }
}

# Generate Ansible inventory file
# Generate Ansible inventory from Terraform outputs
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    instance_ip = aws_instance.study_server.public_ip
    key_path    = "/Users/yasinsaleem/CourseWork/DevOps/vle7/yasinkey.pem"
    aws_region  = var.aws_region
    project_name = var.project_name
  })
  filename = "${path.module}/../ansible/inventory.ini"
  
  depends_on = [aws_instance.study_server]
}