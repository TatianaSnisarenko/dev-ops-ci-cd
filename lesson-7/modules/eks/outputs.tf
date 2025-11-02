output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data for the EKS cluster (Base64-encoded)"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_security_group_id" {
  value       = module.eks.cluster_security_group_id
  description = "Cluster security group ID"
}

output "node_security_group_id" {
  value       = module.eks.node_security_group_id
  description = "Shared node security group ID"
}

output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC provider ARN for IRSA"
}

output "cluster_version" {
  value       = module.eks.cluster_version
  description = "EKS Kubernetes version"
}

output "mng_keys" {
  value       = keys(module.eks.eks_managed_node_groups)
  description = "Managed node group keys (their logical names)"
}

output "mng_asg_names" {
  value       = module.eks.eks_managed_node_groups_autoscaling_group_names
  description = "ASG names created by the managed node groups"
}
