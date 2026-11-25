################################################################################
# Terraform Module: NAT Gateway & Route Tables
# Phụ trách: Võ Duy Hiếu (Leader) - 23520498
# Môn học: NT548 - Công nghệ DevOps và Ứng dụng (Lab 1)
################################################################################

# 1. Cấp phát 1 Elastic IP (EIP) cho NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-eip"
  })
}

# 2. Tạo NAT Gateway đặt tại Public Subnet và gắn Elastic IP
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat"
  })
}

# 3. Tạo Bảng định tuyến Public (Public Route Table)
# Route 0.0.0.0/0 trỏ tới Internet Gateway để ra ngoài Internet trực tiếp
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-public-rt"
  })
}

# 4. Gắn Bảng định tuyến Public vào Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = var.public_subnet_id
  route_table_id = aws_route_table.public.id
}

# 5. Tạo Bảng định tuyến Private (Private Route Table)
# Route 0.0.0.0/0 trỏ tới NAT Gateway để Private Subnet ra Internet 1 chiều
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-private-rt"
  })
}

# 6. Gắn Bảng định tuyến Private vào Private Subnet
resource "aws_route_table_association" "private" {
  subnet_id      = var.private_subnet_id
  route_table_id = aws_route_table.private.id
}
