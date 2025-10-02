# Outputs for the main environment - C4.md Implementation
# Demonstrates how to expose module outputs

# VPC Outputs
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the created VPC"
}

output "vpc_cidr_block" {
  value       = module.vpc.vpc_cidr_block
  description = "The CIDR block of the VPC"
}

output "subnet_id" {
  value       = module.vpc.subnet_id
  description = "The ID of the created subnet"
}

output "subnet_cidr_block" {
  value       = module.vpc.subnet_cidr_block
  description = "The CIDR block of the subnet"
}

output "internet_gateway_id" {
  value       = module.vpc.internet_gateway_id
  description = "The ID of the internet gateway"
}

output "route_table_id" {
  value       = module.vpc.route_table_id
  description = "The ID of the route table"
}

# EKS Cluster Outputs - C4.md Implementation
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

# RDS Database Outputs - C4.md Implementation
output "db_instance_id" {
  description = "RDS instance ID"
  value       = module.rds.db_instance_id
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = module.rds.db_instance_port
}

output "db_instance_name" {
  description = "RDS database name"
  value       = module.rds.db_instance_name
}

output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = module.rds.db_credentials_secret_arn
  sensitive   = true
}

# Application URLs - C4.md Implementation
output "task_manager_url" {
  description = "URL for the Task Manager API"
  value       = "https://api-${var.environment}.student-team4.local"
}

output "grafana_url" {
  description = "URL for Grafana monitoring dashboard"
  value       = "https://grafana-${var.environment}.student-team4.local"
}

# Kubernetes Access Information
output "kubectl_config_command" {
  description = "Command to configure kubectl for this cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

# Environment Information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "availability_zone" {
  value       = module.vpc.availability_zone
  description = "The availability zone of the subnet"
}
