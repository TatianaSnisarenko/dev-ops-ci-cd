resource "helm_release" "argo_cd" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version

  create_namespace = true

  values = [
    file("${path.module}/values.yaml")
  ]
}

resource "helm_release" "argo_apps" {
  name      = "${var.name}-apps"
  namespace = var.namespace
  chart     = "${path.module}/charts"

  create_namespace = false

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [
    helm_release.argo_cd
  ]
}
