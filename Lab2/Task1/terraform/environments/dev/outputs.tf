output "public_bastion_ip" {
  description = "Dia chi IP Public cua Bastion Host de SSH vao"
  value       = module.ec2.public_ec2_ip
}

output "private_instance_internal_ip" {
  description = "Dia chi IP noi bo cua Private EC2"
  value       = module.ec2.private_ec2_internal_ip
}

output "ssh_connection_command" {
  description = "Cau lenh mau de SSH vao Bastion Host"
  value       = "ssh -i <duong-dan-vockey.pem> ec2-user@${module.ec2.public_ec2_ip}"
}

output "vpc_id" {
  description = "ID cua VPC de doi chieu ket qua trien khai"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID cua Public Subnet"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "ID cua Private Subnet"
  value       = module.vpc.private_subnet_id
}

output "nat_gateway_id" {
  description = "ID cua NAT Gateway"
  value       = module.nat.nat_gateway_id
}

output "nat_eip" {
  description = "Elastic IP de doi chieu outbound cua Private EC2"
  value       = module.nat.nat_eip
}

output "public_route_table_id" {
  description = "ID cua Public Route Table"
  value       = module.nat.public_route_table_id
}

output "private_route_table_id" {
  description = "ID cua Private Route Table"
  value       = module.nat.private_route_table_id
}
