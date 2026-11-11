resource "aws_cloudwatch_metric_alarm" "primary_health" {
  count = var.primary_alb_dns_name == null ? 0 : 1

  provider = aws.virginia

  alarm_name        = "cloudrecover-primary-health-alarm"
  alarm_description = "Primary application or database health check failed"

  namespace   = "AWS/Route53"
  metric_name = "HealthCheckStatus"
  statistic   = "Minimum"
  alarm_actions = [
    aws_sns_topic.route53_health_alerts[0].arn
  ]

  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = 1
  comparison_operator = "LessThanThreshold"

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary[0].id
  }

  treat_missing_data = "breaching"

  tags = {
    Name    = "cloudrecover-primary-health-alarm"
    Project = "CloudRecover"
  }
}

resource "aws_cloudwatch_metric_alarm" "recovery_health" {
  count = var.recovery_alb_dns_name == null ? 0 : 1

  provider = aws.virginia

  alarm_name        = "cloudrecover-recovery-health-alarm"
  alarm_description = "Recovery application or database health check failed"

  namespace   = "AWS/Route53"
  metric_name = "HealthCheckStatus"
  statistic   = "Minimum"

  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = 1
  comparison_operator = "LessThanThreshold"

  dimensions = {
    HealthCheckId = aws_route53_health_check.recovery[0].id
  }

  treat_missing_data = "breaching"

  tags = {
    Name    = "cloudrecover-recovery-health-alarm"
    Project = "CloudRecover"
  }
}
