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

output "node_group_name" {
  description = "EKS managed node group name"
  value       = module.eks.eks_managed_node_groups["default"].node_group_name
}
