terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
      Environment = "lab-5"
    }
  }
}


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
  vpc_name           = "lesson-5-vpc"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-5-ecr"
  scan_on_push = true
}
