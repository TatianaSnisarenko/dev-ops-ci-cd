output "endpoint" {
  description = "Database endpoint (hostname)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : aws_db_instance.standard[0].address
}

output "port" {
  description = "Database port"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].port : aws_db_instance.standard[0].port
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
}

output "master_username" {
  description = "Master username"
  value       = var.username
}

output "master_password" {
  description = "Master password passed to the module"
  value       = var.password
  sensitive   = true
}

output "security_group_id" {
  description = "RDS/Aurora security group ID"
  value       = aws_security_group.rds.id
}
