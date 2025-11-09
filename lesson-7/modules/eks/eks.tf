terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  name = var.cluster_name
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.12"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  authentication_mode                      = var.authentication_mode
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  enable_irsa                              = var.enable_irsa
  
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  cluster_addons = {
    vpc-cni = {
    most_recent = true
    configuration_values = jsonencode({
      env = {
        ENABLE_PREFIX_DELEGATION = "true"
        WARM_PREFIX_TARGET       = "1"
      }
    })
  }
    kube-proxy             = { most_recent = true }
    coredns                = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true }
  }

  eks_managed_node_groups = {
    (var.node_group_name) = {
      ami_type       = "AL2_x86_64"
      disk_size      = var.disk_size
      instance_types = var.instance_types

      min_size     = var.min_size
      desired_size = var.desired_size
      max_size     = var.max_size
    }
  }

  access_entries = var.enable_admin_access ? {
    for arn in var.admin_iam_arns :
    replace(arn, ":", "-") => {
      principal_arn = arn
      policy_associations = {
        cluster_admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  } : {}

  tags = merge(
    {
      Module      = "eks"
    },
    var.tags
  )
}
