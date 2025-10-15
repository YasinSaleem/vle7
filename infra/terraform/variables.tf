variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
  default     = "vle7-app"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
  
  validation {
    condition = contains(["t2.micro", "t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Supported instance types: t2.micro, t3.micro, t3.small, t3.medium."
  }
}

variable "key_name" {
  description = "AWS EC2 Key Pair name for SSH access"
  type        = string
  default     = "yasinkey"
}