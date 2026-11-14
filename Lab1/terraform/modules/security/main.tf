# 1. Security Group cho Public EC2 (Bastion Host)
resource "aws_security_group" "public_ec2_sg" {
  name        = "${var.project_name}-public-ec2-sg"
  description = "Allow SSH inbound traffic from specific user IP only"
  vpc_id      = var.vpc_id

  # Chieu di vao (Inbound/Ingress): Chi cho phep SSH (port 22) tu IP cu the
  ingress {
    description = "SSH from allowed user IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_ip]
  }

  # Chieu di ra (Outbound/Egress): Cho phep di ra moi noi (Internet & Private Subnet)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-public-ec2-sg"
  }
}

# 2. Security Group cho Private EC2
resource "aws_security_group" "private_ec2_sg" {
  name        = "${var.project_name}-private-ec2-sg"
  description = "Allow SSH and ICMP only from Public EC2 Security Group"
  vpc_id      = var.vpc_id

  # Chieu di vao 1: Chi cho phep SSH (port 22) tu cac may thuoc Public EC2 SG
  ingress {
    description     = "SSH from Bastion Host (Public EC2 SG)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_ec2_sg.id]
  }

  # Chieu di vao 2: Cho phep Ping (ICMP) tu Bastion Host de kiem tra ket noi mang
  ingress {
    description     = "ICMP Ping from Bastion Host (Public EC2 SG)"
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.public_ec2_sg.id]
  }

  # Chieu di ra (Outbound/Egress): Mo ra ngoai de ket noi Internet qua NAT Gateway
  egress {
    description = "Allow all outbound traffic via NAT Gateway"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-private-ec2-sg"
  }
}