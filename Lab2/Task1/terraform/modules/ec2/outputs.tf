output "public_ec2_ip" {
  description = "Dia chi IP Public cua Bastion Host"
  value       = aws_instance.public_ec2.public_ip
}

output "private_ec2_internal_ip" {
  description = "Dia chi IP noi bo cua Private EC2"
  value       = aws_instance.private_ec2.private_ip
}
