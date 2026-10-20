
variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "target_group_name" {
  description = "Name of the application target group"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs in different Availability Zones for the internet-facing ALB"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "Provide at least two public subnet IDs."
  }
}

variable "alb_security_group_id" {
  description = "ID of the ALB security group from the security module"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC containing the target group and application instances"
  type        = string
}

variable "instance_ids" {
  description = "EC2 instance IDs to register with the target group"
  type        = list(string)
}

variable "target_port" {
  description = "Port on which the application listens"
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "HTTP path used to check application health"
  type        = string
  default     = "/"
}

variable "environment" {
  description = "Deployment environment, such as primary or recovery"
  type        = string
}

