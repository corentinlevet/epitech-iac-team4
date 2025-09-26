terraform {
  required_version = ">= 1.8.0"

  # Backend config is provided via -backend-config=... file
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}
