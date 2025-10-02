# Production environment variables
# Demonstrates different configuration for production

region                  = "us-west-2"
project_name            = "student-team4-iac"
environment             = "prod"
vpc_name                = "student-team4-prod-vpc"
cidr_block              = "10.1.0.0/16"
subnet_cidr_block       = "10.1.1.0/24"
map_public_ip_on_launch = false

# EKS Configuration - C4.md Implementation
kubernetes_version = "1.28"

# GitHub Runners - Production (larger scale)
runner_instance_types = ["t3.medium", "t3.large"]
runner_desired_size   = 2
runner_max_size       = 10
runner_min_size       = 1

# Application Nodes - Production
app_instance_types = ["t3.medium", "t3.large"]
app_desired_size   = 3
app_max_size       = 20
app_min_size       = 2

# RDS Configuration - Production (larger instance)
postgres_version           = "15.14"
db_instance_class          = "db.t3.small"
db_allocated_storage       = 50
db_max_allocated_storage   = 200
db_backup_retention_period = 14
db_deletion_protection     = true
db_skip_final_snapshot     = false
