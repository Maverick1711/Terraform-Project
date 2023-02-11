output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.myapp-rds.address
  sensitive   = true
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.myapp-rds.port
  sensitive   = true
}

output "db_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.myapp-rds.username
  sensitive   = true
}

output "db_password" {
  value       = aws_db_instance.myapp-rds.password
  description = "The password for logging in to the database."
  sensitive   = true
}