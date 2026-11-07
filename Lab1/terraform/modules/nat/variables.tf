################################################################################
# Variables for NAT & Routing Module (Lab 1)
# Phụ trách: Võ Duy Hiếu (Leader) - 23520498
################################################################################

variable "project_name" {
  description = "Tên project dùng làm tiền tố gắn tag tài nguyên"
  type        = string
  default     = "NT548-Lab1"
}

variable "vpc_id" {
  description = "ID của VPC (nhận từ output của module vpc)"
  type        = string
}

variable "public_subnet_id" {
  description = "ID của Public Subnet nơi đặt NAT Gateway (nhận từ module vpc)"
  type        = string
}

variable "private_subnet_id" {
  description = "ID của Private Subnet cần định tuyến qua NAT (nhận từ module vpc)"
  type        = string
}

variable "internet_gateway_id" {
  description = "ID của Internet Gateway để Public Route trỏ tới (nhận từ module vpc)"
  type        = string
}

variable "tags" {
  description = "Các tags bổ sung áp dụng cho tài nguyên"
  type        = map(string)
  default     = {}
}

