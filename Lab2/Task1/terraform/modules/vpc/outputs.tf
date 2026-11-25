################################################################################
# Outputs for VPC Module (Lab 1)
# Phụ trách: Võ Duy Hiếu (Leader) - 23520498
################################################################################

output "vpc_id" {
  description = "ID của VPC vừa khởi tạo"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block của VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "ID của Public Subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID của Private Subnet"
  value       = aws_subnet.private.id
}

output "internet_gateway_id" {
  description = "ID của Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "default_security_group_id" {
  description = "ID của Default Security Group thuộc VPC"
  value       = aws_default_security_group.default.id
}
