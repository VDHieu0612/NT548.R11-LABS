# Offline tests: the mock provider does not call AWS or create real resources.
mock_provider "aws" {}

variables {
  allowed_ssh_ip = "192.0.2.10/32"
}

run "accept_single_ipv4_and_preserve_lab1_defaults" {
  command = plan

  assert {
    condition     = module.vpc.vpc_cidr_block == "10.0.0.0/16"
    error_message = "The default Lab 1 VPC CIDR must be preserved."
  }

  assert {
    condition     = var.aws_region == "us-east-1" && var.availability_zone == "us-east-1a"
    error_message = "The default Lab 1 Region and Availability Zone must be preserved."
  }
}

run "accept_matching_region_and_zone" {
  command = plan

  variables {
    aws_region        = "us-west-2"
    availability_zone = "us-west-2a"
  }
}

run "reject_world_open_ssh" {
  command = plan

  variables {
    allowed_ssh_ip = "0.0.0.0/0"
  }

  expect_failures = [var.allowed_ssh_ip]
}

run "reject_malformed_ssh_cidr" {
  command = plan

  variables {
    allowed_ssh_ip = "YOUR_PUBLIC_IP/32"
  }

  expect_failures = [var.allowed_ssh_ip]
}

run "reject_ipv6_ssh_cidr" {
  command = plan

  variables {
    allowed_ssh_ip = "2001:db8::1/128"
  }

  expect_failures = [var.allowed_ssh_ip]
}

run "reject_mismatched_region_and_zone" {
  command = plan

  variables {
    aws_region        = "us-west-2"
    availability_zone = "us-east-1a"
  }

  expect_failures = [var.availability_zone]
}
