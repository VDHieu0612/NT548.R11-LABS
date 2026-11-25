variable "project_name" {
  description = "Ten du an dung de dat ten cho cac tai nguyen"
  type        = string
  default     = "NT548-Lab01"
}

variable "instance_type" {
  description = "Loai may ao EC2 (t2.micro hoac t3.micro nam trong gioi han Learner Lab)"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Ten Key Pair da co tren AWS Learner Lab"
  type        = string
  default     = "vockey"
}

variable "public_subnet_id" {
  description = "ID cua Public Subnet de dat Bastion Host"
  type        = string
}

variable "private_subnet_id" {
  description = "ID cua Private Subnet de dat Private EC2"
  type        = string
}

variable "public_security_group_id" {
  description = "ID cua Public Security Group"
  type        = string
}

variable "private_security_group_id" {
  description = "ID cua Private Security Group"
  type        = string
}
