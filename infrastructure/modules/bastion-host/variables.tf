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