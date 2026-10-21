output "vpc_id" {
  description = "ID of the primary VPC"
  value       = module.vpc.vpc_id
}

output "application_instance_ids" {
  description = "IDs of the application EC2 instances"
  value       = module.app_server.app_server_instance_id
}

output "application_key_pair_name" {
  description = "Name of the application server SSH key pair"
  value       = module.app_server.app_server_key_pair_name
}

output "prometheus_key_pair_name" {
  description = "Name of the Prometheus server SSH key pair"
  value       = module.prometheus_server.prometheus_server_key_pair_name
}

output "grafana_key_pair_name" {
  description = "Name of the Grafana server SSH key pair"
  value       = module.grafana_server.grafana_server_key_pair_name
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