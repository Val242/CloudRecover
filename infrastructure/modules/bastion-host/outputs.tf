output "bastion_instance_id" {
  description = "The ID of the bastion host EC2 instance"
  value       = aws_instance.bastion.id
}

output "bastion_instance_state" {
  description = "State configured for the bastion host EC2 instance"
  value       = aws_ec2_instance_state.bastion_state.state
}

output "bastion_key_pair_name" {
  description = "Name of the bastion host SSH key pair"
  value       = aws_key_pair.bastion.key_name
}
