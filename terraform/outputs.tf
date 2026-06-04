output "region" {
  value = var.region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "security_group_id" {
  value = module.security_group.security_group_id
}