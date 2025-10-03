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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Remote backend configuration for team collaboration
  # The bucket must be created manually before terraform init
  # Backend config is loaded via -backend-config flag to support multiple environments

  backend "s3" {
    # Configuration loaded from ../backends/{env}.config files
  }
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

# Configure Kubernetes Provider
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# Configure Helm Provider
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
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

# EKS Cluster Module - C4.md Implementation
module "eks" {
  source = "../modules/eks"

  cluster_name       = "${var.project_name}-${var.environment}-cluster"
  environment        = var.environment
  project_name       = var.project_name
  kubernetes_version = var.kubernetes_version

  # Use subnets from VPC module
  subnet_ids         = module.vpc.subnet_ids
  private_subnet_ids = module.vpc.subnet_ids

  # GitHub Runners configuration
  runner_instance_types = var.runner_instance_types
  runner_desired_size   = var.runner_desired_size
  runner_max_size       = var.runner_max_size
  runner_min_size       = var.runner_min_size

  # Application configuration
  app_instance_types = var.app_instance_types
  app_desired_size   = var.app_desired_size
  app_max_size       = var.app_max_size
  app_min_size       = var.app_min_size

  depends_on = [module.vpc]
}

# RDS Database Module - C4.md Implementation
module "rds" {
  source = "../modules/rds"

  db_name      = "${var.project_name}-${var.environment}"
  environment  = var.environment
  project_name = var.project_name

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.subnet_ids
  allowed_cidr_blocks = [var.cidr_block]

  postgres_version      = var.postgres_version
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage

  backup_retention_period = var.db_backup_retention_period
  deletion_protection     = var.db_deletion_protection
  skip_final_snapshot     = var.db_skip_final_snapshot

  depends_on = [module.vpc]
}

# Helm Releases - C4.md Implementation

# Deploy AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.2"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.eks.load_balancer_controller_role_arn
  }

  depends_on = [module.eks]
}

# Kubernetes Secret for Database Credentials - temporarily commented out
# resource "kubernetes_secret" "db_credentials" {
#   metadata {
#     name      = "task-manager-db-credentials"
#     namespace = "default"
#   }
# 
#   data = {
#     url      = "postgresql://${module.rds.db_instance_username}:placeholder@${module.rds.db_instance_endpoint}:${module.rds.db_instance_port}/${module.rds.db_instance_name}"
#     host     = module.rds.db_instance_endpoint
#     port     = tostring(module.rds.db_instance_port)
#     dbname   = module.rds.db_instance_name
#     username = module.rds.db_instance_username
#     password = "placeholder" # Will be updated via external secret operator
#   }
# 
#   depends_on = [module.rds]
# }

# Deploy Task Manager Application
# Commented out for initial infrastructure deployment
# resource "helm_release" "task_manager" {
#   name      = "task-manager"
#   chart     = "../../helm-charts/task-manager"
#   namespace = "default"
# 
#   values = [
#     yamlencode({
#       replicaCount = var.environment == "prod" ? 3 : 2
# 
#       image = {
#         repository = "task-manager"
#         tag        = "latest"
#       }
# 
#       database = {
#         secretName = kubernetes_secret.db_credentials.metadata[0].name
#       }
# 
#       ingress = {
#         enabled   = true
#         className = "alb"
#         hosts = [{
#           host = "api-${var.environment}.student-team4.local"
#           paths = [{
#             path     = "/"
#             pathType = "Prefix"
#           }]
#         }]
#       }
# 
#       resources = var.environment == "prod" ? {
#         limits = {
#           cpu    = "500m"
#           memory = "512Mi"
#         }
#         requests = {
#           cpu    = "250m"
#           memory = "256Mi"
#         }
#         } : {
#         limits = {
#           cpu    = "250m"
#           memory = "256Mi"
#         }
#         requests = {
#           cpu    = "100m"
#           memory = "128Mi"
#         }
#       }
#     })
#   ]
# 
#   depends_on = [
#     module.eks,
#     module.rds,
#     kubernetes_secret.db_credentials,
#     helm_release.aws_load_balancer_controller
#   ]
# }

# Deploy Monitoring Stack
# Commented out for initial infrastructure deployment
# resource "helm_release" "monitoring" {
#   name      = "monitoring"
#   chart     = "../../helm-charts/monitoring"
#   namespace = "monitoring"
# 
#   create_namespace = true
# 
#   values = [
#     yamlencode({
#       "kube-prometheus-stack" = {
#         prometheus = {
#           prometheusSpec = {
#             retention     = var.environment == "prod" ? "30d" : "7d"
#             retentionSize = var.environment == "prod" ? "100GiB" : "20GiB"
# 
#             storageSpec = {
#               volumeClaimTemplate = {
#                 spec = {
#                   storageClassName = "gp3"
#                   accessModes      = ["ReadWriteOnce"]
#                   resources = {
#                     requests = {
#                       storage = var.environment == "prod" ? "100Gi" : "20Gi"
#                     }
#                   }
#                 }
#               }
#             }
#           }
#         }
# 
#         grafana = {
#           persistence = {
#             enabled          = true
#             storageClassName = "gp3"
#             size             = var.environment == "prod" ? "20Gi" : "10Gi"
#           }
# 
#           ingress = {
#             enabled   = true
#             className = "alb"
#             hosts     = ["grafana-${var.environment}.student-team4.local"]
#           }
#         }
#       }
#     })
#   ]
# 
#   depends_on = [
#     module.eks,
#     helm_release.aws_load_balancer_controller
#   ]
# }
