resource "aws_db_snapshot" "cloudrecover_database_snapshot" {
  db_instance_identifier = "my-existing-rds-instance-id"
  db_snapshot_identifier = "my-manual-snapshot-name"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
