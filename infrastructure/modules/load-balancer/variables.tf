
variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "app_target_group_name" {
  description = "Name of the application target group"
  type        = string
}

variable "prometheus_target_group_name" {
  description = "Name of the Prometheus target group"
  type        = string
}

variable "grafana_target_group_name" {
  description = "Name of the Grafana target group"
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

variable "app_instance_ids" {
  description = "Application EC2 instance IDs to register with the application target group"
  type        = list(string)
}

variable "prometheus_instance_ids" {
  description = "Prometheus EC2 instance IDs to register with the Prometheus target group"
  type        = list(string)
}

variable "grafana_instance_ids" {
  description = "Grafana EC2 instance IDs to register with the Grafana target group"
  type        = list(string)
}

variable "app_target_port" {
  description = "Port on which the application listens"
  type        = number
  default     = 3000
}

variable "prometheus_target_port" {
  description = "Port on which Prometheus listens"
  type        = number
  default     = 9090
}

variable "grafana_target_port" {
  description = "Port on which Grafana listens"
  type        = number
  default     = 3000
}

variable "app_health_check_path" {
  description = "HTTP path used to check application health"
  type        = string
  default     = "/"
}

variable "prometheus_health_check_path" {
  description = "HTTP path used to check Prometheus health"
  type        = string
  default     = "/-/healthy"
}

variable "grafana_health_check_path" {
  description = "HTTP path used to check Grafana health"
  type        = string
  default     = "/api/health"
}

variable "environment" {
  description = "Deployment environment, such as primary or recovery"
  type        = string
}

