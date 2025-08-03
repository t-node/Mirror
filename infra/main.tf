terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Generate random suffix for resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  name_prefix = "mirror-${random_string.suffix.result}"
}

# Frontend module
module "frontend" {
  source = "./modules/frontend"
  
  name_prefix = local.name_prefix
  aws_region  = var.aws_region
}

# Backend module
module "backend" {
  source = "./modules/backend"
  
  name_prefix           = local.name_prefix
  aws_region           = var.aws_region
  cloudfront_domain    = module.frontend.cloudfront_domain_name
  cors_allowed_origins = ["https://${module.frontend.cloudfront_domain_name}"]
}

# Outputs
output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = "https://${module.frontend.cloudfront_domain_name}"
}

output "api_base_url" {
  description = "API Gateway HTTP API endpoint"
  value       = module.backend.http_api_endpoint
}

output "frontend_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = module.frontend.frontend_bucket_name
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.backend.lambda_function_name
}

output "api_execution_logs_group" {
  description = "CloudWatch log group for API Gateway"
  value       = module.backend.api_execution_logs_group
} 