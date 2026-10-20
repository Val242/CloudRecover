output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.app_alb.arn
}

output "alb_dns_name" {
  description = "DNS name used to access the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "target_group_arn" {
  description = "ARN of the application target group"
  value       = aws_lb_target_group.app_tg.arn
}

output "alb_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}
