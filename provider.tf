terraform {
  required_version = "~> 1.2"
  required_providers {
    aws = {
      source  = "aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "kubernetes"
      version = "~> 2.0"
    }
    tls = {
      source  = "tls"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = local.project_name
  default_tags {
    tags = {
      Environment = terraform.workspace
    }
  }
}
