# Production environment variables
# Demonstrates different configuration for production

region                  = "us-west-2"
project_name            = "student-team4-iac"
environment             = "prod"
vpc_name                = "student-team4-prod-vpc"
cidr_block              = "10.1.0.0/16"
subnet_cidr_block       = "10.1.1.0/24"
map_public_ip_on_launch = false
