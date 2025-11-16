output "argo_cd_server_service" {
  description = "Argo CD server service DNS name"
  value       = "argo-cd-server.${var.namespace}.svc.cluster.local"
}

output "admin_password" {
  description = "Command to get initial admin password"
  value       = "kubectl -n ${var.namespace} get secret argocd-initial-admin-secret -o jsonpath={.data.password} | base64 -d"
}
