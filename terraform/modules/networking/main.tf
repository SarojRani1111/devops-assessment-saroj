module "vpc" {
  source  = "clouddrove/vpc/aws"
  version = "~> 0.19.0"

  name        = "${var.project_name}-${var.environment}-vpc"
  environment = var.environment

  cidr_block = var.cidr_block

  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_ipv6 = false

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}