# VPC and Subnet (AWS)

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = {
    Name    = var.vpc_name
    Project = var.project_id
    Env     = "dev"
  }
}

resource "aws_subnet" "main" {
  vpc_id                 = aws_vpc.main.id
  cidr_block             = var.subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.vpc_name}-subnet"
    Project = var.project_id
    Env     = "dev"
  }
}
