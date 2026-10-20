
variable "vpc_id" {
  description = "ID of the VPC in which security groups are created"
  type        = string
}

variable "my_ip" {
  description = "Administrator public IPv4 address in CIDR notation, for example 203.0.113.10/32"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.my_ip))
    error_message = "my_ip must be a valid IPv4 CIDR, such as 203.0.113.10/32."
  }
}

variable "project" {
  description = "Project identifier used in resource names and tags"
  type        = string
  default     = "cloudrecover"
}

variable "environment" {
  description = "Environment or region role, such as primary or recovery"
  type        = string

  validation {
    condition     = contains(["primary", "recovery"], var.environment)
    error_message = "environment must be either primary or recovery."
  }
}
