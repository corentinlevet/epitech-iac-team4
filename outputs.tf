# Outputs

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the created VPC"
}

output "subnet_id" {
  value       = aws_subnet.main.id
  description = "The ID of the created Subnet"
}
