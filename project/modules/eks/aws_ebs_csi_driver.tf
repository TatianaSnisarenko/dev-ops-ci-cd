###############################################
# Read existing EKS cluster (created by module "eks")
###############################################
data "aws_eks_cluster" "this" {
  name = var.cluster_name

  depends_on = [module.eks]
}

###############################################
# Locals for OIDC info
###############################################
locals {
  oidc_issuer = data.aws_eks_cluster.this.identity[0].oidc[0].issuer

  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(local.oidc_issuer, "https://", "")}"
}

###############################################
# IAM Role for EBS CSI Driver (IRSA)
###############################################
resource "aws_iam_role" "ebs_csi_irsa_role" {
  name = "${var.cluster_name}-ebs-csi-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = local.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(local.oidc_issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

###############################################
# Attach official AWS EBS CSI policy
###############################################
resource "aws_iam_role_policy_attachment" "ebs_irsa_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_irsa_role.name
}

###############################################
# INSTALL EBS CSI DRIVER ADDON
###############################################
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = data.aws_eks_cluster.this.name

  addon_name    = "aws-ebs-csi-driver"
  addon_version = "v1.41.0-eksbuild.1" # з твого конспекту

  service_account_role_arn = aws_iam_role.ebs_csi_irsa_role.arn

  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_iam_role_policy_attachment.ebs_irsa_policy
  ]
}
