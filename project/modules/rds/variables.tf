variable "name" {
  description = "Base name for RDS/Aurora (used in identifiers / group names)"
  type        = string
}

variable "use_aurora" {
  description = "If true — create an Aurora Cluster; if false — create a regular RDS instance"
  type        = bool
  default     = false
}

# -------------------
# Engine for RDS
# -------------------
variable "engine" {
  description = "Engine for regular RDS (postgres, mysql, etc.)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version for regular RDS (e.g., 17.2)"
  type        = string
  default     = "17.2"
}

variable "parameter_group_family_rds" {
  description = "Parameter group family for RDS (e.g., postgres17)"
  type        = string
  default     = "postgres17"
}

# -------------------
# Engine for Aurora
# -------------------
variable "engine_cluster" {
  description = "Engine for Aurora (aurora-postgresql, aurora-mysql)"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version_cluster" {
  description = "Engine version for Aurora (e.g., 15.3)"
  type        = string
  default     = "15.3"
}

variable "parameter_group_family_aurora" {
  description = "Parameter group family for Aurora (e.g., aurora-postgresql15)"
  type        = string
  default     = "aurora-postgresql15"
}

variable "aurora_replica_count" {
  description = "Number of read-replica instances for Aurora"
  type        = number
  default     = 1
}

# -------------------
# Common instance parameters
# -------------------
variable "instance_class" {
  description = "EC2 instance class for RDS / Aurora (db.t3.micro, db.t3.medium, ...)"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage size for regular RDS (GB). Not used for Aurora"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "username" {
  description = "Database user (master / admin)"
  type        = string
}

variable "password" {
  description = "Database user password"
  type        = string
  sensitive   = true
}

# -------------------
# Network
# -------------------
variable "vpc_id" {
  description = "VPC ID where the database will be deployed"
  type        = string
}

variable "subnet_private_ids" {
  description = "List of private subnets for RDS/Aurora"
  type        = list(string)
}

variable "subnet_public_ids" {
  description = "List of public subnets (if publicly_accessible = true)"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Whether the instance should be publicly accessible"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Enable Multi-AZ for regular RDS"
  type        = bool
  default     = false
}

variable "vpc_cidr_block" {
  description = "VPC CIDR for security group ingress (access to DB from the whole VPC)"
  type        = string
}

# -------------------
# Parameters, backups and tags
# -------------------
variable "parameters" {
  description = "Map of parameters for the parameter group (max_connections, log_min_duration_statement, etc.)"
  type        = map(string)
  default     = {}
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups (0 = disabled)"
  type        = string
  default     = "0"
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
