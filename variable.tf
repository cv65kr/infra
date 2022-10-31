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

variable "helm_prometheus_version" {
  default = "15.9.0"
}

variable "helm_kiali_version" {
  default = "1.55.1"
}

variable "helm_grafana_version" {
  default = "6.31.1"
}

variable "helm_flagger_version" {
  default = "1.24.1"
}

variable "telepresence_enabled" {
  default = true
}

variable "helm_telepresence_version" {
  default = "2.8.3"
}

variable "release_version" {
  default = "1.0.0"
}