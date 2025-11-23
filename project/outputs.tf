output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS API endpoint"
}

output "eks_cluster_ca_b64" {
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
  description = "Base64 cluster CA"
}

output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC provider ARN"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "ECR repository URL to push the Django image"
}

output "kubectl_update_cmd" {
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region} --profile ${var.aws_profile}"
  description = "Command to configure kubectl to talk to this cluster"
}

output "metrics_server_release" {
  value       = helm_release.metrics_server.name
  description = "Deployed Helm release name for metrics-server"
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds_postgres.endpoint
}

output "rds_db_name" {
  description = "RDS database name"
  value       = module.rds_postgres.db_name
}

output "rds_master_username" {
  description = "RDS master username"
  value       = module.rds_postgres.master_username
}

output "rds_sg_id" {
  description = "RDS Security Group ID"
  value       = module.rds_postgres.security_group_id
}

output "jenkins_release_name" {
  description = "Helm release name for Jenkins"
  value       = module.jenkins.jenkins_release_name
}

output "jenkins_namespace" {
  description = "Namespace where Jenkins is installed"
  value       = module.jenkins.jenkins_namespace
}

output "argo_cd_server_service" {
  description = "Argo CD server service DNS name (cluster internal)"
  value       = module.argo_cd.argo_cd_server_service
}

output "argo_cd_admin_password_hint" {
  description = "How to get initial admin password for Argo CD"
  value       = module.argo_cd.admin_password
}



