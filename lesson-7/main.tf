terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # Needed to talk to the EKS cluster from Terraform
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
    # Needed to install charts (Metrics Server) from Terraform
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

provider "aws" {
  region  = "eu-north-1"
  profile = "terraform"

  # Global tags applied to all resources
  default_tags {
    tags = {
      Project     = "devops"
      Environment = "lesson-7"
    }
  }
}

# ------------------------------
# Core infrastructure modules
# ------------------------------


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
  vpc_name           = "lesson-7-vpc"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-7-ecr"
  scan_on_push = true
}

module "eks" {
  source = "./modules/eks"

  cluster_name = "lesson-7-eks"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids

  desired_size = 1
  min_size     = 1
  max_size     = 2

  # Grant the calling IAM user cluster-admin via aws-auth
  manage_aws_auth = true
  map_users = [
    {
      userarn  = data.aws_caller_identity.current.arn
      username = "terraform"
      groups   = ["system:masters"]
    }
  ]
}

# ------------------------------
# Connect Terraform to EKS
# ------------------------------

# --- EKS connection data ---
data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# --- Kubernetes provider (kubectl-style ops from Terraform) ---
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# --- Helm provider (to install charts like Metrics Server) ---
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
    load_config_file       = false
  }
}

# ------------------------------
# Install Metrics Server (for HPA)
# ------------------------------

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.1"

  namespace        = "kube-system"
  create_namespace = false
  wait             = true
  timeout          = 300

  depends_on = [module.eks]
}

# (Optional) Quick metrics smoke test after apply
resource "null_resource" "smoke_metrics" {
  provisioner "local-exec" {
    command = "kubectl top nodes || echo 'metrics not ready yet'"
  }

  depends_on = [helm_release.metrics_server]
}

