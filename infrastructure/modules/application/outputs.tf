output "app_server_instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.app-server.id
}

output "app_server_state" {
  description = "State of the web server"
  value = aws_ec2_instance_state.app-server-state.state
}

