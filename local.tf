data "aws_partition" "current" {}

locals {
  container_id = "${var.environment}-${var.kubernetes_cluster_name}-${replace(var.dns_zone_name, ".", "-")}"

  dns_suffix = data.aws_partition.current.dns_suffix

  tags = merge(
    var.tags,
    tomap({ "Environment" = var.environment }),
  )

  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "aws"
    clusters = [{
      name = module.eks.cluster_id
      cluster = {
        certificate-authority-data = module.eks.cluster_certificate_authority_data
        server                     = module.eks.cluster_endpoint
      }
    }]
    contexts = [{
      name = "aws"
      context = {
        cluster = module.eks.cluster_id
        user    = "aws"
      }
    }]
    users = [{
      name = "aws"
      user = {
        token = data.aws_eks_cluster_auth.this.token
      }
    }]
  })
}