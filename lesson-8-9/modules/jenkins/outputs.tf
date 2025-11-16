output "jenkins_release_name" {
  value       = helm_release.jenkins.name
  description = "Name of the Jenkins Helm release"
}

output "jenkins_namespace" {
  value       = helm_release.jenkins.namespace
  description = "Namespace where Jenkins is deployed"
}
