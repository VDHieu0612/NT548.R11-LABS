################################################################################
# Outputs for NAT & Routing Module (Lab 1)
# Phụ trách: Võ Duy Hiếu (Leader) - 23520498
################################################################################

output "nat_gateway_id" {
  description = "ID của NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "nat_eip" {
  description = "Địa chỉ IP tĩnh (Elastic IP) của NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "public_route_table_id" {
  description = "ID của Public Route Table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID của Private Route Table"
  value       = aws_route_table.private.id
}
