# Simple valid Terraform configuration for working-directory test
terraform {
  required_version = ">= 1.0"
}

variable "name" {
  description = "Resource name"
  type        = string
  default     = "example"
}
