data "aws_iam_policy_document" "eks_cluster" {
  statement {
    sid     = "EKSClusterAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.${local.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${local.container_id}-eks-iam"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster.json
}