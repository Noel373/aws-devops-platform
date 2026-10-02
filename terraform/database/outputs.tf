output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.petclinic.id
}

output "db_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.petclinic.address
}

output "db_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.petclinic.port
}

output "db_name" {
  description = "PostgreSQL database name"
  value       = aws_db_instance.petclinic.db_name
}

output "db_username" {
  description = "PostgreSQL username"
  value       = aws_db_instance.petclinic.username
}

output "db_security_group_id" {
  description = "Security group attached to PostgreSQL"
  value       = aws_security_group.postgres.id
}

output "db_subnet_group_name" {
  description = "RDS subnet group"
  value       = aws_db_subnet_group.petclinic.name
}

output "db_password" {
  description = "Generated PostgreSQL password"
  value       = random_password.db_password.result
  sensitive   = true
}