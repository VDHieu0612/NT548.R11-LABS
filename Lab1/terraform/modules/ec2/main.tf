# Tu dong tim Amazon Linux 2023 AMI moi nhat
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 1. May ao Public (Bastion Host) dat o Public Subnet
resource "aws_instance" "public_ec2" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.public_security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true # Bat IP cong khai de SSH tu ngoai vao

  tags = {
    Name = "${var.project_name}-public-bastion"
  }
}

# 2. May ao Private dat o Private Subnet
resource "aws_instance" "private_ec2" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [var.private_security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = false # Khong co IP cong khai de dam bao bao mat

  tags = {
    Name = "${var.project_name}-private-ec2"
  }
}