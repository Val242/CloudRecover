# The primary state creates the private zone and associates its VPC. The
# recovery state associates its VPC and manages its own failover record.
resource "aws_route53_zone" "application" {
  count = var.create_hosted_zone ? 1 : 0

  name          = var.domain_name
  comment       = "${var.project} application DNS zone"
  force_destroy = false

  vpc {
    vpc_id     = var.vpc_id
    vpc_region = var.vpc_region
  }

  tags = {
    Project = var.project
  }

  # The recovery state adds its VPC with aws_route53_zone_association.
  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_route53_zone_association" "environment" {
  count = var.create_hosted_zone ? 0 : 1

  zone_id    = var.hosted_zone_id
  vpc_id     = var.vpc_id
  vpc_region = var.vpc_region
}

locals {
  hosted_zone_id = var.create_hosted_zone ? aws_route53_zone.application[0].zone_id : var.hosted_zone_id
}

resource "aws_route53_record" "application" {
  zone_id         = local.hosted_zone_id
  name            = var.record_name
  type            = "A"
  set_identifier  = "${var.project}-${lower(var.failover_type)}"
  health_check_id = var.failover_type == "PRIMARY" ? aws_route53_health_check.primary[0].id : aws_route53_health_check.recovery[0].id

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = var.failover_type
  }
}

resource "aws_route53_health_check" "primary" {
  count = var.primary_alb_dns_name == null ? 0 : 1

  fqdn              = var.primary_alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/health/ready"
  failure_threshold = 2
  request_interval  = 10

  tags = {
    Name    = "cloudrecover-primary-health-check"
    Project = "CloudRecover"
  }
}


resource "aws_route53_health_check" "recovery" {
  count = var.recovery_alb_dns_name == null ? 0 : 1

  fqdn              = var.recovery_alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/health/ready"
  failure_threshold = 2
  request_interval  = 10

  tags = {
    Name    = "cloudrecover-recovery-health-check"
    Project = "CloudRecover"
  }
}

resource "aws_sns_topic" "primary_health_alerts" {
  name = "cloudrecover-primary-health-alerts"

  tags = {
    Name    = "cloudrecover-primary-health-alerts"
    Project = "CloudRecover"
  }
}

