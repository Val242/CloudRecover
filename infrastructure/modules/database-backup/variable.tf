variable "db_instance_identifier" {
  description = "Identifier of the RDS instance to back up"
  type        = string
}

variable "db_snapshot_identifier" {
  description = "Name of the manual RDS snapshot"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}