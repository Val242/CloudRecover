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

resource "aws_lb_target_group" "app_tg" {
  name        = var.target_group_name
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name        = var.target_group_name
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

resource "aws_lb_target_group_attachment" "app" {
  for_each = toset(var.instance_ids)

  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = each.value
  port             = var.target_port
}
