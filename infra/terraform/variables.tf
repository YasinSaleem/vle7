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
  default     = "yasinkey"  # Set to our key name
}

variable "instance_type" {
  description = "EC2 instance type - t3.small for minikube support (NOT FREE TIER)"
  type        = string
  default     = "t3.small"  # t3.small: 2 vCPU, 2GB RAM - Required for minikube
  
  validation {
    condition = contains(["t2.micro", "t3.micro", "t3.small"], var.instance_type)
    error_message = "Supported instance types: t2.micro, t3.micro (free tier) or t3.small (paid)."
  }
}

# Example terraform.tfvars file (optional):
# aws_region    = "us-west-2"
# key_name      = "my-key-pair"  
# instance_type = "t3.small"    # PAID INSTANCE: ~$0.0208/hour (~$15/month)

# COST WARNING:
# - t3.small is NOT FREE TIER (~$15/month)
# - Use t2.micro or t3.micro for free tier (but insufficient for minikube)
# - Remember to destroy infrastructure when done: terraform destroy