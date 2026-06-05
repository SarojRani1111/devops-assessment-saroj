module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-${var.environment}-vpc"
  cidr = var.cidr_block

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}


resource "aws_internet_gateway" "this" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Project     = var.project_name
    Environment = var.environment
  }
}

module "subnets" {
  source  = "clouddrove/subnet/aws"
  version = "2.0.2"

  name        = "${var.project_name}-${var.environment}"
  environment = var.environment

  vpc_id = module.vpc.vpc_id

  availability_zones = var.azs
  type               = "public-private"

  ipv4_public_cidrs  = var.public_subnets
  ipv4_private_cidrs = var.private_subnets

  nat_gateway_enabled = true
  single_nat_gateway  = true
  igw_id              = aws_internet_gateway.this.id
}