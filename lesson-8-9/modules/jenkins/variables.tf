variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for the EKS cluster (from module.eks)"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL for the EKS cluster"
  type        = string
}
