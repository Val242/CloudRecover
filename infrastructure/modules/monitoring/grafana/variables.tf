variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type = string
}

variable "instance_name" {
   description = "Grafana Server's name"
   type = string
   default = "grafana-server"
}

variable "key_name" {
  description = "Name of the SSH key pair for the Grafana server"
  type        = string
}

variable "grafana_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
}

variable "environment" {
  description = "Deployment environment used for resource tagging"
  type        = string
}