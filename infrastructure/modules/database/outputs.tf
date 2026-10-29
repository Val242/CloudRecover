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

output "db_instance_identifier" {
  description = "Identifier of the CloudRecover RDS instance"
  value       = aws_db_instance.cloudrecover_database.identifier
}

output "snapshot_identifier" {
  description = "Snapshot identifier used for database restoration"
  value       = var.snapshot_identifier
}
