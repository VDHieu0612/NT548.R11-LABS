variable "aws_region" {
  description = "Region AWS trien khai (Learner Lab bat buoc dung us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Ten du an"
  type        = string
  default     = "NT548-Lab01"
}

variable "allowed_ssh_ip" {
  description = "Dia chi IP Public cua ban duoc phep SSH (dinh dang CIDR, vi du: 113.161.x.x/32)"
  type        = string
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