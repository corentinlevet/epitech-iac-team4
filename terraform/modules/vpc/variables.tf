# Variables for VPC Module
# Demonstrates parameterization as mentioned in C1.md best practices

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "The cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "subnet_cidr_block" {
  type        = string
  description = "CIDR block for the subnet"
  validation {
    condition     = can(cidrhost(var.subnet_cidr_block, 0))
    error_message = "The subnet_cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "map_public_ip_on_launch" {
  type        = bool
  description = "Specify true to indicate that instances launched into the subnet should be assigned a public IP address"
  default     = true
}
