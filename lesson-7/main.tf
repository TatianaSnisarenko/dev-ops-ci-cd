terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.31"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.13.2"
    }
  }
}

############################
# Providers
############################

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}



############################
# Modules
############################


module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "terraform-state-bucket-a3f7d92c"
  table_name  = "terraform-locks"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24","10.0.5.0/24","10.0.6.0/24"]
  availability_zones = ["eu-north-1a","eu-north-1b","eu-north-1c"]
  vpc_name           = "lab-vpc"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lab-ecr"
  scan_on_push = true
}
module "eks" {
  source = "./modules/eks"

  cluster_name   = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  enable_cluster_creator_admin_permissions = true

  enable_admin_access = true
  admin_iam_arns     = var.admin_iam_arns

  node_group_name = "ng-default"
  instance_types  = var.instance_types
  min_size        = var.min_size
  desired_size    = var.desired_size
  max_size        = var.max_size
  disk_size       = var.disk_size

  tags = var.tags
}

############################
# Metrics Server Helm Release
############################
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.2"

  namespace        = "kube-system"
  create_namespace = false

  depends_on = [module.eks]
}


