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


# resource "aws_instance"  "this"  {
#   ami           = var.ami_id
#   instance_type = var.instance_type
#   subnet_id     = var.subnet_id

#   tags = {
#     Name = var.instance_name
#   }
# }
