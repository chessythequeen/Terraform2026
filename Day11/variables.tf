variable "environment" {
  description = "Deployment environment (dev or production)"
  type        = string

  validation {
    condition     = contains(["dev", "production"], var.environment)
    error_message = "Invalid environment. Must be 'dev' or 'production'."
  }
}

locals {
  is_production = var.environment == "production"

  instance_type = local.is_production ? "t2.medium" : "t2.micro"
  min_size      = local.is_production ? 3 : 1
  max_size      = local.is_production ? 6 : 2
}