################################################################################
# Terraform Module: VPC Network
# Phụ trách: Võ Duy Hiếu (Leader) - 23520498
# Môn học: NT548 - Công nghệ DevOps và Ứng dụng (Lab 1)
################################################################################

# 1. Tạo Virtual Private Cloud (VPC)
resource "aws_vpc" "main" {
  #checkov:skip=CKV2_AWS_11:EX-012 Flow Logs require extra logging/IAM resources beyond the preserved Lab 1 topology.
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc"
  })
}

# 2. Tạo Internet Gateway (IGW) và gắn vào VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-igw"
  })
}

# 3. Tạo Public Subnet (dành cho Bastion Host & NAT Gateway)
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.availability_zone
  # Bastion explicitly requests its Public IP; unrelated instances get none by default.
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-public-subnet"
    Type = "Public"
  })
}

# 4. Tạo Private Subnet (dành cho Private EC2 Instance / Backend)
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-private-subnet"
    Type = "Private"
  })
}

# 5. Cấu hình Default Security Group cho VPC
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # EC2 instances use dedicated SGs; keep the unused Default SG closed.
  ingress = []
  egress  = []

  tags = merge(var.tags, {
    Name = "${var.project_name}-default-sg"
  })
}
