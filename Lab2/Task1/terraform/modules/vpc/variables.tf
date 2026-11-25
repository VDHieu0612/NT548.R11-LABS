################################################################################
# Variables for VPC Module (Lab 1)
# Phụ trách: Võ Duy Hiếu (Leader) - 23520498
################################################################################

variable "project_name" {
  description = "Tên project dùng làm tiền tố gắn tag tài nguyên"
  type        = string
  default     = "NT548-Lab1"
}

variable "vpc_cidr" {
  description = "Dải địa chỉ CIDR block của VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Dải CIDR của Public Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Dải CIDR của Private Subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability Zone để đặt Subnets (ví dụ: us-east-1a)"
  type        = string
  default     = "us-east-1a"
}

variable "tags" {
  description = "Các tags bổ sung áp dụng cho tài nguyên"
  type        = map(string)
  default     = {}
}
