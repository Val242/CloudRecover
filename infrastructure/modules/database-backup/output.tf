output "snapshot_id" {
  description = "Identifier of the created RDS snapshot"
  value       = aws_db_snapshot.cloudrecover_database_snapshot.id
}

output "snapshot_arn" {
  description = "ARN of the created RDS snapshot"
  value       = aws_db_snapshot.cloudrecover_database_snapshot.db_snapshot_arn
}