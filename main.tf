terraform {
  required_version = ">= 1.2"
  required_providers {
    aws = {
      source  = "aws"
      version = ">= 4.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "= 2.5.1"
    }
    kubernetes = {
      source  = "kubernetes"
      version = ">= 2.14"
    }
    tls = {
      source  = "tls"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = local.tags
  }
}

provider "local" {}

module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v3.18.0"
  name   = "${local.container_id}-vpc"
  cidr   = "10.0.0.0/16"
  azs = [
    data.aws_availability_zones.availability_zones.names[0],
    data.aws_availability_zones.availability_zones.names[1],
    data.aws_availability_zones.availability_zones.names[2]
  ]
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_dns_hostnames = true

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  tags = merge(
    local.tags,
    tomap({ "kubernetes.io/cluster/${local.container_id}-eks" = "shared" }),
  )

  public_subnet_tags = merge(
    local.tags,
    tomap({
      "kubernetes.io/cluster/${local.container_id}-eks" = "shared",
      "kubernetes.io/role/elb"                          = "1"
    }),
  )
}

module "eks" {
  source       = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v18.30.2"
  cluster_name = "${local.container_id}-eks"
  subnet_ids   = module.vpc.public_subnets
  vpc_id       = module.vpc.vpc_id
  iam_role_arn = aws_iam_role.eks_cluster.arn

  node_security_group_additional_rules = {
    allow_all_internal_ranges = {
      description = "Allow all inbound range from internal addresses"
      protocol    = "all"
      from_port   = 0
      to_port     = 65535
      type        = "ingress"
      cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "100.64.0.0/10"]
    }
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    inbound_from_eks_api = {
      description                   = "Inbound from the EKS API to all EKS nodes"
      protocol                      = "tcp"
      from_port                     = 0
      to_port                       = 65535
      type                          = "ingress"
      source_cluster_security_group = true
    }

  }
  manage_aws_auth_configmap = true

  # Encryption key
  create_kms_key = true
  cluster_encryption_config = [{
    resources = ["secrets"]
  }]
  kms_key_deletion_window_in_days = 7
  enable_kms_key_rotation         = true

  eks_managed_node_groups = {
    main : {
      min_size     = lookup(var.auto_scale_options, "min")
      max_size     = lookup(var.auto_scale_options, "max")
      desired_size = lookup(var.auto_scale_options, "desired")

      instance_types = var.nodes_instances_sizes
      capacity_type  = "SPOT"

      labels = {
        instance_type = "ec2"
      }
    }
  }

  fargate_profiles = {
    tools = {
      name       = "tools"
      subnet_ids = module.vpc.private_subnets
      selectors = [
        {
          # Look on istio.tf
          namespace = "tools"
        }
      ]
    }
  }
}