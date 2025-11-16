output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "cluster_id" {
  value       = module.eks.cluster_id
  description = "EKS cluster ID"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS API server endpoint"
}

output "cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
  description = "Base64-encoded cluster CA"
}

output "cluster_security_group_id" {
  value       = module.eks.cluster_security_group_id
  description = "Cluster security group ID"
}

output "cluster_primary_security_group_id" {
  value       = module.eks.cluster_primary_security_group_id
  description = "Primary security group ID for the cluster"
}

output "node_group_role_arn" {
  value       = try(module.eks.eks_managed_node_group_iam_role_arn[var.node_group_name], null)
  description = "IAM Role ARN of the default managed node group"
}

output "kubectl_update_command" {
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name}"
  description = "Handy command to configure kubectl for this cluster"
}

output "eks_access_entries_info" {
  value = {
    enabled        = var.enable_admin_access
    admin_iam_arns = var.admin_iam_arns
  }
  description = "Who gets cluster-admin via Access Entries"
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint for connecting to the cluster"
  value       = data.aws_eks_cluster.this.endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = data.aws_eks_cluster.this.name
}


output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = local.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "OIDC issuer URL"
  value       = local.oidc_issuer
}
