variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

terraform {
  required_version = ">= 1.6.0"
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
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4.0"
    }
    random = { 
      source = "hashicorp/random"
       version = ">= 3.5.0"
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

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  name        = var.cluster_name
  my_ip_cidr  = "${chomp(data.http.my_ip.response_body)}/32"
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

  repository_cache       = "${path.root}/.helm/cache"
  repository_config_path = "${path.root}/.helm/repositories.yaml"
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
  vpc_cidr_block     = var.vpc_cidr_block
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
  vpc_name           = "lab-vpc"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = var.ecr_repository_name
  scan_on_push = true
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  enable_cluster_creator_admin_permissions = true
  enable_admin_access                      = true
  admin_iam_arns                           = var.admin_iam_arns

  node_group_name = "ng-default"
  instance_types  = var.instance_types
  min_size        = var.min_size
  desired_size    = var.desired_size
  max_size        = var.max_size
  disk_size       = var.disk_size

  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = [local.my_ip_cidr]

  tags = var.tags
}

############################
# Metrics Server Helm Release (needed for HPA)
############################
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.2"

  namespace        = "kube-system"
  create_namespace = false

  wait            = true
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true

  values = [
    yamlencode({
      hostNetwork = { enabled = false }   # було true → зробимо false
      args = [
        "--kubelet-insecure-tls"
      ]
      resources = {
        limits   = { cpu = "100m", memory = "128Mi" }
        requests = { cpu = "50m",  memory = "64Mi" }
      }
      replicas = 1
    })
  ]

  depends_on = [module.eks]
}


############################################
# RDS PostgreSQL (module)
############################################

resource "random_password" "rds_master" {
  length           = 24
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1

  special          = true
  override_special = "!#$%&()*+,-.:;<=>?[]^_{|}~\\"
}


module "rds_postgres" {
  source             = "./modules/rds"
  cluster_name       = var.cluster_name
  vpc_id             = module.vpc.vpc_id
  vpc_cidr_block     = var.vpc_cidr_block
  private_subnet_ids = module.vpc.private_subnet_ids

  db_name         = var.db_name
  master_username = var.db_username
  master_password = random_password.rds_master.result

}

############################################
# Kubernetes Secret with DB creds for Django
############################################
resource "kubernetes_secret_v1" "django_db" {
  count    = var.create_db_secret ? 1 : 0
  metadata {
    name      = var.db_secret_name 
    namespace = var.k8s_namespace  
  }

  data = {
    DB_HOST     = module.rds_postgres.endpoint
    DB_PORT     = tostring(module.rds_postgres.port)
    DB_NAME     = module.rds_postgres.db_name
    DB_USER     = module.rds_postgres.master_username
    DB_PASSWORD = module.rds_postgres.master_password

    POSTGRES_HOST     = module.rds_postgres.endpoint
    POSTGRES_PORT     = tostring(module.rds_postgres.port)
    POSTGRES_DB       = module.rds_postgres.db_name
    POSTGRES_USER     = module.rds_postgres.master_username
    POSTGRES_PASSWORD = module.rds_postgres.master_password

    DATABASE_URL = "postgresql://${module.rds_postgres.master_username}:${module.rds_postgres.master_password}@${module.rds_postgres.endpoint}:${module.rds_postgres.port}/${module.rds_postgres.db_name}"
  }

  type = "Opaque"

  depends_on = [
    module.eks,
    data.aws_eks_cluster.this,
    data.aws_eks_cluster_auth.this
  ]
}



