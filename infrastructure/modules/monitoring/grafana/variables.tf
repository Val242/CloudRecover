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