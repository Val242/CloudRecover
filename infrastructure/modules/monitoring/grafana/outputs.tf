output "grafana_server_instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.grafana-server.id
}

variable "grafana_security_group_id" {
  description = "ID of the Prometheus security group from the security module"
  type        = string
}