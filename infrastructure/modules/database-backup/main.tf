resource "aws_db_snapshot" "cloudrecover_database_snapshot" {
  db_instance_identifier = var.db_instance_identifier
  db_snapshot_identifier = var.db_snapshot_identifier

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}