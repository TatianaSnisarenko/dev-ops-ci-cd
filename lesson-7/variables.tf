variable "region" {
  type        = string
  description = "AWS region"
  default     = "eu-north-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile to use"
  default     = "terraform"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
  default     = "lab-eks"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for EKS"
  default     = "1.30"
}

variable "admin_iam_arns" {
  type        = list(string)
  description = "Additional IAM ARNs to grant cluster-admin via Access Entries"
  default     = []
}

variable "ecr_repository_name" {
  type        = string
  description = "ECR repo name for the Django app image"
  default     = "lab-ecr"
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "min_size" {
  type    = number
  default = 2
}
variable "desired_size" {
  type    = number
  default = 2
}
variable "max_size" {
  type    = number
  default = 6
}
variable "disk_size" {
  type    = number
  default = 30
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "devops"
    Environment = "lab"
  }
}
