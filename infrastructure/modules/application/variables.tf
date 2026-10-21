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
   description = "Application Server's name"
   type = string
   default = "cloud-recover-api"
}

variable "app_server_security_group_id" {
  description = "ID of the app server security group from the security module"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair for the application server"
  type        = string
}

variable "app_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
}

variable "environment" {
  description = "Deployment environment used for resource tagging"
  type        = string
}
