# Simple Terraform Variables for Study Environment
# Update these values in terraform.tfvars or pass them via CLI

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"  # Updated to match actual deployment
}

variable "key_name" {
  description = "AWS EC2 Key Pair name for SSH access (create one in AWS console first)"
  type        = string
  default     = ""  # Can be empty - instance will work without SSH key
}

variable "instance_type" {
  description = "EC2 instance type - Free tier options: t2.micro, t3.micro"
  type        = string
  default     = "t3.micro"  # AWS Free Tier: 750 hours/month for 12 months
  
  validation {
    condition = contains(["t2.micro", "t3.micro"], var.instance_type)
    error_message = "For free tier compatibility, use t2.micro or t3.micro."
  }
}

# Example terraform.tfvars file (optional):
# aws_region    = "us-west-2"
# key_name      = "my-key-pair"  
# instance_type = "t3.micro"    # Default - or "t2.micro" also free tier eligible

# AWS Free Tier includes:
# - 750 hours/month of t2.micro or t3.micro instances (12 months)
# - 30 GB of EBS storage
# - 15 GB of bandwidth