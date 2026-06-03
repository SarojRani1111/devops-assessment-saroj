variable "project_name" {}
variable "environment" {}

variable "subnet_ids" {
  type = list(string)
}

variable "cluster_version" {
  default = "1.29"
}

variable "vpc_id" {
  type = string
}