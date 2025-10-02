# EKS Module Variables

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "student-team4-iac"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "subnet_ids" {
  description = "List of subnet IDs for EKS cluster"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for node groups"
  type        = list(string)
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks for public API access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# GitHub Runners Node Group Variables
variable "runner_instance_types" {
  description = "Instance types for GitHub runners node group"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

variable "runner_desired_size" {
  description = "Desired number of GitHub runner nodes"
  type        = number
  default     = 1
}

variable "runner_max_size" {
  description = "Maximum number of GitHub runner nodes"
  type        = number
  default     = 5
}

variable "runner_min_size" {
  description = "Minimum number of GitHub runner nodes"
  type        = number
  default     = 0
}

# Application Node Group Variables
variable "app_instance_types" {
  description = "Instance types for application node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "app_desired_size" {
  description = "Desired number of application nodes"
  type        = number
  default     = 2
}

variable "app_max_size" {
  description = "Maximum number of application nodes"
  type        = number
  default     = 10
}

variable "app_min_size" {
  description = "Minimum number of application nodes"
  type        = number
  default     = 1
}

# EKS Add-on Versions
variable "coredns_version" {
  description = "CoreDNS add-on version"
  type        = string
  default     = "v1.10.1-eksbuild.5"
}

variable "kube_proxy_version" {
  description = "kube-proxy add-on version"
  type        = string
  default     = "v1.28.2-eksbuild.2"
}

variable "vpc_cni_version" {
  description = "VPC CNI add-on version"
  type        = string
  default     = "v1.15.1-eksbuild.1"
}
