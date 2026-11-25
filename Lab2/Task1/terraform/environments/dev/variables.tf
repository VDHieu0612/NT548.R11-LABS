variable "aws_region" {
  description = "Region AWS trien khai; mac dinh giu us-east-1 cua Lab 1"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Availability Zone cua hai subnet, phai thuoc aws_region"
  type        = string
  default     = "us-east-1a"

  validation {
    condition     = can(regex("^${var.aws_region}[a-z]$", var.availability_zone))
    error_message = "availability_zone phai thuoc aws_region (vi du us-east-1 va us-east-1a)."
  }
}

variable "project_name" {
  description = "Ten du an"
  type        = string
  default     = "NT548-Lab01"
}

variable "allowed_ssh_ip" {
  description = "Dia chi IP Public cua ban duoc phep SSH (dinh dang CIDR, vi du: 113.161.x.x/32)"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.allowed_ssh_ip)) && can(regex("/32$", var.allowed_ssh_ip))
    error_message = "allowed_ssh_ip phai la dia chi IPv4 hop le voi prefix /32; khong mo SSH cho ca mang."
  }
}

variable "instance_type" {
  description = "Loai may ao EC2"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Ten Key Pair tren AWS Learner Lab"
  type        = string
  default     = "vockey"
}
