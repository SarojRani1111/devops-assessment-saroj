terraform {
  backend "s3" {
    bucket         = "saroj-eks-tfstate-2026"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}