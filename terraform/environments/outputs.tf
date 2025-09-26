# Outputs for the main environment
# Demonstrates how to expose module outputs

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

output "availability_zone" {
  value       = module.vpc.availability_zone
  description = "The availability zone of the subnet"
}
