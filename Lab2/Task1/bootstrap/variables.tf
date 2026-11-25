variable "aws_region" {
  description = "Region cua bucket luu Terraform state"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Ten S3 bucket duy nhat toan cau; nguoi dung tu dien"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "state_bucket_name can 3-63 ky tu chu thuong, so, dau gach ngang; bat dau/ket thuc bang chu hoac so."
  }
}
