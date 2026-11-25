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
  #checkov:skip=CKV_AWS_126:EX-001 Detailed monitoring is outside the budgeted Lab 1 baseline; see security-exceptions.json.
  #checkov:skip=CKV_AWS_135:EX-002 Preserve t2.micro; EBS optimization is not supported by that baseline instance type.
  #checkov:skip=CKV_AWS_88:EX-003 Public IP is required for the Lab 1 Bastion; SSH remains restricted to one IPv4 /32.
  #checkov:skip=CKV2_AWS_41:EX-004 No workload needs AWS APIs; do not create IAM roles in Learner Lab just to satisfy a scan.
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.public_security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true # Bat IP cong khai de SSH tu ngoai vao

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "${var.project_name}-public-bastion"
  }
}

# 2. May ao Private dat o Private Subnet
resource "aws_instance" "private_ec2" {
  #checkov:skip=CKV_AWS_126:EX-005 Preserve basic monitoring and the Lab 1 cost baseline.
  #checkov:skip=CKV_AWS_135:EX-006 Preserve t2.micro; EBS optimization is not supported by that baseline instance type.
  #checkov:skip=CKV2_AWS_41:EX-007 No AWS API workload or instance role is required by this lab.
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [var.private_security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = false # Khong co IP cong khai de dam bao bao mat

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "${var.project_name}-private-ec2"
  }
}
