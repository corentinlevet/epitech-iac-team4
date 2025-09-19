terraform {
  required_version = ">= 1.8.0"

  backend "s3" {
    bucket         = "terraform-backend-epitech-2025" # ton bucket
    key            = "state/terraform.tfstate"
    region         = "eu-west-3" # Paris
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "example" {
  bucket = "terraform-demo-bucket-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4
}
