output "bastion_instance_id" {
  description = "The ID of the bastion host EC2 instance"
  value       = aws_instance.bastion.id
}