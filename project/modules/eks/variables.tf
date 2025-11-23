variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "Existing VPC ID to place the EKS cluster into"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for worker nodes/control plane endpoints"
  type        = list(string)
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Bootstrap cluster-admin for the cluster creator"
  type        = bool
  default     = true
}

variable "enable_admin_access" {
  description = "Toggle to create access entries for admin_iam_arns as cluster-admins"
  type        = bool
  default     = true
}

variable "admin_iam_arns" {
  description = "List of IAM user/role ARNs to grant cluster-admin via EKS Access Entries"
  type        = list(string)
  default     = []
}

variable "node_group_name" {
  description = "Name of the default managed node group"
  type        = string
  default     = "ng-default"
}

variable "instance_types" {
  description = "Instance types for the node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "min_size" {
  type        = number
  description = "Min nodes in the node group"
  default     = 2
}

variable "desired_size" {
  type        = number
  description = "Desired nodes in the node group"
  default     = 3
}

variable "max_size" {
  type        = number
  description = "Max nodes in the node group"
  default     = 3
}

variable "disk_size" {
  description = "Node root volume size (GiB)"
  type        = number
  default     = 30
}

variable "authentication_mode" {
  description = "EKS authentication mode"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (OIDC provider)"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to EKS API endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to EKS API endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "Allowed CIDRs for public EKS endpoint"
  type        = list(string)
  default     = [] # значення підставимо у root-рівні
}
