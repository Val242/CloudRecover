output "prometheus_server_instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.prometheus-server.id
}

output "prometheus_server_state" {
  description = "State of the web server"
  value = aws_ec2_instance_state.prometheus-server-state.state
}

output "prometheus_server_key_pair_name" {
  description = "Name of the Prometheus server SSH key pair"
  value       = aws_key_pair.cloudrecover-private-server.key_name
}