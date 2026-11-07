terraform {
  required_version = ">= 1.0"
}

locals {
  greeting = "hello"
}

output "greeting" {
  description = "A greeting"
  value       = local.greeting
}
