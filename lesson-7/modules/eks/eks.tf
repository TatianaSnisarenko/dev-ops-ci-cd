###########################################
# EKS CLUSTER + MANAGED NODE GROUP MODULE #
###########################################

# Official AWS EKS Terraform module
# It automatically creates:
#  - EKS control plane (API server, IAM roles, networking)
#  - Managed node group (EC2 worker nodes)
#  - All necessary IAM roles and policies
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  eks_managed_node_groups = {
    default = {
      desired_size = var.desired_size
      min_size     = var.min_size
      max_size     = var.max_size

      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 20
    }
  }

  # Allow API server public access (for demo / testing only)
  cluster_endpoint_public_access = true
}
