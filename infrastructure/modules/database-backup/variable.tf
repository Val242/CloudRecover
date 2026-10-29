variable "db_instance_identifier" {
  description = "Identifier of the RDS instance"
  type        = string
}

variable "db_snapshot_identifier" {
  description = "Identifier of the database snapshot"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}