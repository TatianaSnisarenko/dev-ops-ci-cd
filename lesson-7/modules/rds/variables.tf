variable "cluster_name" {
  description = "Logical name prefix (use your EKS cluster/app name)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR (for SG ingress to 5432)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "appuser"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "RDS storage size (GiB)"
  type        = number
  default     = 20
}
