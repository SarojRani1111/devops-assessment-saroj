variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "cluster_version" {
  type    = string
  default = "1.30"
}

variable "vpc_id" {
  type = string
}