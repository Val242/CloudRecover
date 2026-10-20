variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20
}

variable "engine" {
  description = "The database engine type (e.g., mysql, postgres)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "The engine version"
  type        = string
  default     = "15.4"
}

variable "rds_security_group_id" {
  description = "Security group ID for the RDS database"
  type        = string
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "The name of the database to create"
  type        = string
  default     = "mydb"
}

variable "username" {
  description = "Master username for the database"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the database"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
