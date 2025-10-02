# Development environment variables
# Demonstrates environment-specific configuration

region                  = "us-east-1"
project_name            = "student-team4-iac"
environment             = "dev"
vpc_name                = "student-team4-dev-vpc"
cidr_block              = "10.0.0.0/16"
subnet_cidr_block       = "10.0.1.0/24"
map_public_ip_on_launch = true

# EKS Configuration - C4.md Implementation
kubernetes_version = "1.28"

# GitHub Runners - Development (smaller scale)
runner_instance_types = ["t3.micro"]
runner_desired_size   = 1
runner_max_size       = 2
runner_min_size       = 0

# Application Nodes - Development
app_instance_types = ["t3.micro"]
app_desired_size   = 1
app_max_size       = 2
app_min_size       = 1

# RDS Configuration - Development (smaller instance)
postgres_version           = "15.14"
db_instance_class          = "db.t3.micro"
db_allocated_storage       = 20
db_max_allocated_storage   = 50
db_backup_retention_period = 3
db_deletion_protection     = false
db_skip_final_snapshot     = true
