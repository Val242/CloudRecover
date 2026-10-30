output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.app_alb.arn
}

output "alb_dns_name" {
  description = "DNS name used to access the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "app_target_group_arn" {
  description = "ARN of the application target group"
  value       = aws_lb_target_group.app_tg.arn
}

output "prometheus_target_group_arn" {
  description = "ARN of the Prometheus target group"
  value       = try(aws_lb_target_group.prometheus_tg[0].arn, null)
}

output "grafana_target_group_arn" {
  description = "ARN of the Grafana target group"
  value       = try(aws_lb_target_group.grafana_tg[0].arn, null)
}

output "alb_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "prometheus_listener_arn" {
  description = "ARN of the Prometheus listener"
  value       = try(aws_lb_listener.prometheus[0].arn, null)
}

output "grafana_listener_arn" {
  description = "ARN of the Grafana listener"
 value       = try(aws_lb_listener.grafana[0].arn, null)
}
