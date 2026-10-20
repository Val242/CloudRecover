output "endpoint" {
  description = "The connection endpoint"
  value       = aws_db_instance.cloudrecover_database.endpoint
}

output "address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.cloudrecover_database.address
}

output "id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.cloudrecover_database.id
}
