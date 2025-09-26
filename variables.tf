# Variables

variable "project_id" {
  type        = string
  description = "Cloud project ID (tagging/naming purpose)"
}

variable "region" {
  type        = string
  description = "AWS region for resources (e.g., eu-west-3)"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for the VPC (e.g., 10.0.0.0/16)"
}

variable "subnet_cidr_block" {
  type        = string
  description = "CIDR block for the subnet (e.g., 10.0.1.0/24)"
}
