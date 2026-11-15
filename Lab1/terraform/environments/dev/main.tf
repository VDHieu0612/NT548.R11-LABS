# 1. Goi module VPC 
module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
}

# 2. Goi module NAT Gateway & Route Tables 
module "nat" {
  source              = "../../modules/nat"
  project_name        = var.project_name
  vpc_id              = module.vpc.vpc_id
  public_subnet_id    = module.vpc.public_subnet_id
  private_subnet_id   = module.vpc.private_subnet_id
  internet_gateway_id = module.vpc.internet_gateway_id
}

# 3. Goi module Security Groups 
module "security" {
  source         = "../../modules/security"
  project_name   = var.project_name
  vpc_id         = module.vpc.vpc_id
  allowed_ssh_ip = var.allowed_ssh_ip
}

# 4. Goi module EC2 Instances 
module "ec2" {
  source                   = "../../modules/ec2"
  project_name             = var.project_name
  instance_type            = var.instance_type
  key_name                 = var.key_name
  public_subnet_id         = module.vpc.public_subnet_id
  private_subnet_id        = module.vpc.private_subnet_id
  public_security_group_id = module.security.public_security_group_id
  private_security_group_id = module.security.private_security_group_id
}