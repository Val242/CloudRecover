output "record_name" {
  description = "DNS name routed to this environment's load balancer"
  value       = aws_route53_record.application.name
}

output "record_fqdn" {
  description = "Fully qualified DNS name of this failover record"
  value       = aws_route53_record.application.fqdn
}

output "hosted_zone_id" {
  description = "ID of the hosted zone containing this record"
  value       = aws_route53_record.application.zone_id
}

output "hosted_zone_name" {
  description = "Name of the private Route 53 hosted zone"
  value       = var.domain_name
}

output "set_identifier" {
  description = "Route 53 set identifier for this environment's record"
  value       = aws_route53_record.application.set_identifier
}

output "failover_type" {
  description = "Failover role configured for this record"
  value       = aws_route53_record.application.failover_routing_policy[0].type
}

output "primary_health_check_id" {
  description = "ID of the primary ALB Route 53 health check, when created"
  value       = try(aws_route53_health_check.primary[0].id, null)
}

output "recovery_health_check_id" {
  description = "ID of the recovery ALB Route 53 health check, when created"
  value       = try(aws_route53_health_check.recovery[0].id, null)
}
