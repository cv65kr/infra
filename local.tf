data "aws_partition" "current" {}

locals {
  container_id = "${var.environment}-${var.kubernetes_cluster_name}-${replace(var.dns_zone_name, ".", "-")}"

  dns_suffix = data.aws_partition.current.dns_suffix

  tags = merge(
    var.tags,
    tomap({
      "Environment"     = var.environment,
      "Release-version" = var.release_version,
    }),
  )
}