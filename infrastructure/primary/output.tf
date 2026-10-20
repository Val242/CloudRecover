output "vpc_id" {
  description = "ID of the primary VPC"
  value       = module.vpc.vpc_id
}

output "application_instance_ids" {
  description = "IDs of the application EC2 instances"
  value       = module.app_server.app_server_instance_id
}

output "load_balancer_dns_name" {
  description = "DNS name of the application load balancer"
  value       = module.load_balancer.alb_dns_name
}

output "web_security_group_id" {
  description = "Security group ID for application instances"
  value       = module.security_groups.web_security_group_id
}

output "database_security_group_id" {
  description = "Security group ID for the database"
  value       = module.security_groups.rds_security_group_id
}