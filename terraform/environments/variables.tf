# Variables for main environment configuration
# Following Terraform best practices from C1.md

variable "region" {
  type        = string
  description = "AWS region for resources"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "student-team4-iac"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
  default     = "student-team4-vpc"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
  type        = string
  description = "CIDR block for the subnet"
  default     = "10.0.1.0/24"
}

variable "map_public_ip_on_launch" {
  type        = bool
  description = "Specify true to indicate that instances launched into the subnet should be assigned a public IP address"
  default     = true
}

# EKS Cluster Variables - C4.md Implementation
variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for EKS cluster"
  default     = "1.28"
}

# GitHub Runners Node Group Variables
variable "runner_instance_types" {
  type        = list(string)
  description = "Instance types for GitHub runners node group"
  default     = ["t3.medium", "t3.large"]
}

variable "runner_desired_size" {
  type        = number
  description = "Desired number of GitHub runner nodes"
  default     = 1
}

variable "runner_max_size" {
  type        = number
  description = "Maximum number of GitHub runner nodes"
  default     = 5
}

variable "runner_min_size" {
  type        = number
  description = "Minimum number of GitHub runner nodes"
  default     = 0
}

# Application Node Group Variables
variable "app_instance_types" {
  type        = list(string)
  description = "Instance types for application node group"
  default     = ["t3.medium"]
}

variable "app_desired_size" {
  type        = number
  description = "Desired number of application nodes"
  default     = 2
}

variable "app_max_size" {
  type        = number
  description = "Maximum number of application nodes"
  default     = 10
}

variable "app_min_size" {
  type        = number
  description = "Minimum number of application nodes"
  default     = 1
}

# RDS Database Variables - C4.md Implementation
variable "postgres_version" {
  type        = string
  description = "PostgreSQL version for RDS"
  default     = "15.4"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "Initial storage allocation for RDS instance"
  default     = 20
}

variable "db_max_allocated_storage" {
  type        = number
  description = "Maximum storage allocation for RDS instance (autoscaling)"
  default     = 100
}

variable "db_backup_retention_period" {
  type        = number
  description = "Number of days to retain database backups"
  default     = 7
}

variable "db_deletion_protection" {
  type        = bool
  description = "Enable deletion protection for RDS instance"
  default     = false
}

variable "db_skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot when deleting RDS instance"
  default     = true
}
