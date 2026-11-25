terraform {
  # Cross-variable validation and native S3 locking need modern Terraform.
  # CI uses the exact version recorded in .terraform-version.
  required_version = ">= 1.10.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
