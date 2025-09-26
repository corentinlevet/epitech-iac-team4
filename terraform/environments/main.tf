# Main Terraform Configuration for Dev Environment
# Demonstrates Infrastructure as Code principles from C1.md
# GitHub Actions OIDC integration test - September 26, 2025

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote backend configuration for team collaboration
  # The bucket must be created manually before terraform init
  # Backend config is loaded via -backend-config flag to support multiple environments

  # TODO: Uncomment when S3 backend is ready
  # backend "s3" {
  #   # Configuration loaded from ../backends/{env}.config files
  # }
}

# Configure AWS Provider
provider "aws" {
  region = var.region

  # Default tags applied to all resources
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = var.environment
      Project     = var.project_name
      Team        = "Student-Team4"
    }
  }
}

# Use the VPC module
module "vpc" {
  source = "../modules/vpc"

  vpc_name                = var.vpc_name
  cidr_block              = var.cidr_block
  subnet_cidr_block       = var.subnet_cidr_block
  environment             = var.environment
  project_name            = var.project_name
  map_public_ip_on_launch = var.map_public_ip_on_launch
}
