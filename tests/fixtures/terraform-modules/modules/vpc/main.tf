# Simple valid Terraform module for testing
terraform {
  required_version = ">= 1.0"
}

variable "cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}
