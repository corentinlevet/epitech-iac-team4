# Outputs for VPC Module
# Demonstrates how to expose resource attributes for reuse

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the created VPC"
}

output "vpc_cidr_block" {
  value       = aws_vpc.main.cidr_block
  description = "The CIDR block of the VPC"
}

output "subnet_id" {
  value       = aws_subnet.main[0].id
  description = "The ID of the first subnet"
}

output "subnet_ids" {
  value       = aws_subnet.main[*].id
  description = "The IDs of all created subnets"
}

output "subnet_cidr_block" {
  value       = aws_subnet.main[0].cidr_block
  description = "The CIDR block of the first subnet"
}

output "subnet_cidr_blocks" {
  value       = aws_subnet.main[*].cidr_block
  description = "The CIDR blocks of all subnets"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.main.id
  description = "The ID of the internet gateway"
}

output "route_table_id" {
  value       = aws_route_table.main.id
  description = "The ID of the route table"
}

output "availability_zone" {
  value       = aws_subnet.main[0].availability_zone
  description = "The availability zone of the first subnet"
}

output "availability_zones" {
  value       = aws_subnet.main[*].availability_zone
  description = "The availability zones of all subnets"
}
