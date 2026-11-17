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
