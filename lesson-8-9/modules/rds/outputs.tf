output "endpoint" {
  description = "RDS endpoint (hostname)"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "master_username" {
  description = "Master username"
  value       = aws_db_instance.this.username
}

output "master_password" {
  description = "Master password (generated)"
  value       = aws_db_instance.this.password
  sensitive   = true
}

output "security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}
