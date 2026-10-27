resource "aws_lb" "app_alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"

  subnets = var.public_subnet_ids

  security_groups = [var.alb_security_group_id]

  tags = {
    Name        = var.alb_name
    Environment = var.environment
    Project     = "CloudRecover"
  }
}


#app server target group
resource "aws_lb_target_group" "app_tg" {
  name        = var.app_target_group_name
  port        = var.app_target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.app_health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name        = var.app_target_group_name
    Environment = var.environment
    Project     = "CloudRecover"
  }
}

# prometheus target group

resource "aws_lb_target_group" "prometheus_tg" {
  name        = var.prometheus_target_group_name
  port        = var.prometheus_target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.prometheus_health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name        = var.prometheus_target_group_name
    Environment = var.environment
    Project     = "CloudRecover"
  }
}

# grafana target group
resource "aws_lb_target_group" "grafana_tg" {
  name        = var.grafana_target_group_name
  port        = var.grafana_target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.grafana_health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name        = var.grafana_target_group_name
    Environment = var.environment
    Project     = "CloudRecover"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_listener" "prometheus" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = var.prometheus_target_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus_tg.arn
  }
}

resource "aws_lb_listener" "grafana" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = var.grafana_target_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }
}


resource "aws_lb_target_group_attachment" "app" {
  for_each = {
    for index, instance_id in var.app_instance_ids :
    tostring(index) => instance_id
  }

  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = each.value
  port             = var.app_target_port
}

resource "aws_lb_target_group_attachment" "prometheus" {
  for_each = {
    for index, instance_id in var.prometheus_instance_ids :
    tostring(index) => instance_id
  }

  target_group_arn = aws_lb_target_group.prometheus_tg.arn
  target_id        = each.value
  port             = var.prometheus_target_port
}

resource "aws_lb_target_group_attachment" "grafana" {
  for_each = {
    for index, instance_id in var.grafana_instance_ids :
    tostring(index) => instance_id
  }

  target_group_arn = aws_lb_target_group.grafana_tg.arn
  target_id        = each.value
  port             = var.grafana_target_port
}
