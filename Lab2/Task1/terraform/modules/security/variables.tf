variable "project_name" {
  description = "Ten du an dung de dat ten cho cac tai nguyen (Tag)"
  type        = string
  default     = "NT548-Lab01"
}

variable "vpc_id" {
  description = "ID cua VPC"
  type        = string
}

variable "allowed_ssh_ip" {
  description = "Dia chi IP Public cua nguoi dung duoc phep SSH vao Bastion Host (dinh dang CIDR, vi du: 1.2.3.4/32)"
  type        = string
}