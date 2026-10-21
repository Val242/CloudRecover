output "grafana_server_instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.grafana-server.id
}

variable "grafana_security_group_id" {
  description = "ID of the Prometheus security group from the security module"
  type        = string
}

output "grafana_server_state" {
  description = "State of the grafana server"
  value = aws_ec2_instance_state.grafana-server-state.state
}

output "grafana_server_key_pair_name" {
  description = "Name of the Grafana server SSH key pair"
  value       = aws_key_pair.cloudrecover-private-server.key_name
}
