variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type = string
}

variable "prometheus_security_group_id" {
  description = "ID of the Prometheus security group from the security module"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type = string
}

variable "instance_name" {
   description = "Prometheus Server's name"
   type = string
   default = "prometheus-server"
}