variable "ami_id" {
  description = "AMI ID for the bastion host"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID where the bastion host will be deployed"
  type        = string
}

variable "instance_name" {
  description = "Name tag for the bastion host EC2 instance"
  type        = string
  default     = "cloud-recover-bastion"
}

variable "bastion_security_group_id" {
  description = "ID of the app server security group from the security module"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair for the bastion host"
  type        = string
}

variable "project" {
  description = "Project name used for resource tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment used for resource tagging"
  type        = string
}

variable "public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
}
