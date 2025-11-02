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

data "aws_caller_identity" "current" {}

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
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

# Ensure aws-auth mapping exists (runs locally; requires eksctl or kubectl+aws)
// ...existing code...
resource "null_resource" "ensure_aws_auth" {
  provisioner "local-exec" {
    command = <<EOT
aws eks update-kubeconfig --name ${module.eks.cluster_name} --region eu-north-1 --profile terraform
eksctl create iamidentitymapping --cluster ${module.eks.cluster_name} --region eu-north-1 --profile terraform --arn ${data.aws_caller_identity.current.arn} --username terraform --group system:masters || true
EOT
  }

  depends_on = [module.eks]
}

# Kubernetes provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks","get-token","--cluster-name", module.eks.cluster_name, "--region", "eu-north-1"]
    env = {
      AWS_PROFILE = "terraform"
      AWS_REGION  = "eu-north-1"
    }
  }
}

# Helm provider
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks","get-token","--cluster-name", module.eks.cluster_name, "--region", "eu-north-1"]
      env = {
        AWS_PROFILE = "terraform"
        AWS_REGION  = "eu-north-1"
      }
    }
  }

  repository_cache       = "${path.root}/.helm/cache"
  repository_config_path = "${path.root}/.helm/repositories.yaml"
}


# ------------------------------
# Install Metrics Server (for HPA)
# ------------------------------

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.1"

  force_update      = true
  dependency_update = true

  namespace        = "kube-system"
  create_namespace = false
  wait             = true
  timeout          = 300

  set {
    name  = "args[0]"
    value = "--kubelet-preferred-address-types=InternalIP"
  }
  set {
    name  = "args[1]"
    value = "--kubelet-insecure-tls"
  }
  set {
    name  = "hostNetwork"
    value = "true"
  }

  depends_on = [
    module.eks,
    data.aws_eks_cluster.this,
    data.aws_eks_cluster_auth.this,
    null_resource.ensure_aws_auth,
  ]
}

# Quick metrics smoke test after apply
resource "null_resource" "smoke_metrics" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region eu-north-1 --profile terraform --alias lesson-7-eks && kubectl top nodes || echo 'metrics not ready yet'"
  }

  depends_on = [helm_release.metrics_server]
}


