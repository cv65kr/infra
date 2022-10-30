variable "environment" {
  default = "stg"
}

variable "dns_zone_name" {
  default = "kk.dev"
}

variable "kubernetes_cluster_name" {
  description = "Name for the Kubernetes cluster"
  default     = "k8s"
}

variable "tags" {
  default = {}
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "aws_profile" {
  default = "playground"
}

variable "nodes_instances_sizes" {
  default = [
    "t3.medium"
  ]
}

variable "auto_scale_options" {
  default = {
    min     = 1
    max     = 2
    desired = 1
  }
}

variable "helm_istio_version" {
  default = "1.15.3"
}

variable "release_version" {
  default = "1.0.0"
}