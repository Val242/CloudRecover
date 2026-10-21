
output "web_security_group_id" {
  description = "Security group ID for application EC2 instances"
  value       = aws_security_group.web.id
}

output "alb_security_group_id" {
  description = "Security group ID for the application load balancer"
  value       = aws_security_group.alb.id
}

output "prometheus_security_group_id" {
  description = "Security group ID for Prometheus"
  value       = aws_security_group.prometheus.id
}

output "grafana_security_group_id" {
  description = "Security group ID for Grafana"
  value       = aws_security_group.grafana.id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS PostgreSQL"
  value       = aws_security_group.rds.id
}

output "bastion_security_group_id" {
  description = "Security group ID for the bastion host"
  value = aws_security_group.bastion.id
}
