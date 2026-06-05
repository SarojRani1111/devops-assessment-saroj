# VPC Module
module "vpc" {
  source = "./modules/networking"

  project_name = local.project_name
  environment  = local.environment

  cidr_block = "10.0.0.0/16"

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]

  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# Security Group Module
module "security_group" {
  source = "./modules/security-group"

  project_name = local.project_name
  environment  = local.environment
  vpc_id       = module.vpc.vpc_id
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  project_name = local.project_name
  environment  = local.environment

  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

}