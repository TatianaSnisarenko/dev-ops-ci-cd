###########################################
# GLOBAL OUTPUTS — BACKEND, VPC, ECR, EKS
###########################################

# --- Backend (S3 + DynamoDB) ---
output "s3_bucket_name" {
  description = "Name of the S3 bucket used for Terraform remote backend"
  value       = module.s3_backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking"
  value       = module.s3_backend.dynamodb_table_name
}

# --- VPC ---
output "vpc_id" {
  description = "VPC ID created for the infrastructure"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# --- ECR ---
output "ecr_repository_url" {
  description = "URL of the ECR repository where Docker images are pushed"
  value       = module.ecr.repository_url
}

# --- EKS ---
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Public API endpoint URL for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_node_group_name" {
  description = "Name of the default managed node group"
  value       = module.eks.node_group_name
}
