# Simple valid Terraform configuration for testing
terraform {
  required_version = ">= 1.0"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
