data "aws_availability_zones" "availability_zones" {
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_id
}