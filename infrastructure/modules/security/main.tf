
# Application security group
resource "aws_security_group" "web" {
  name        = "${var.project}-${var.environment}-web-sg"
  description = "Controls access to the CloudRecover application instances"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project}-${var.environment}-web-sg"
    Project     = var.project
    Environment = var.environment
    Component   = "application"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh_from_bastion_host" {
  security_group_id = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.bastion.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  description       = "SSH access from the Bastion IP"
}

resource "aws_vpc_security_group_ingress_rule" "web_node_exporter_from_prometheus" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.prometheus.id
  from_port                    = 9100
  ip_protocol                  = "tcp"
  to_port                      = 9100
  description                 = "Node Exporter metrics from Prometheus"
}

resource "aws_vpc_security_group_ingress_rule" "web_app_from_prometheus" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.prometheus.id
  from_port                    = 3000
  ip_protocol                  = "tcp"
  to_port                      = 3000
  description                 = "Application metrics scraping from Prometheus"
}

resource "aws_vpc_security_group_ingress_rule" "web_app_from_alb" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 3000
  ip_protocol                  = "tcp"
  to_port                      = 3000
  description                 = "Application traffic from the ALB"
}

resource "aws_vpc_security_group_egress_rule" "web_outbound_ipv4" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow outbound IPv4 traffic"
}

resource "aws_vpc_security_group_egress_rule" "web_outbound_ipv6" {
  security_group_id = aws_security_group.web.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
  description       = "Allow outbound IPv6 traffic"
}


# Application Load Balancer security group
resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "Controls HTTP access to the application load balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project}-${var.environment}-alb-sg"
    Project     = var.project
    Environment = var.environment
    Component   = "load-balancer"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_from_internet" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  description       = "Allow public HTTP traffic"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_web" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 3000
  ip_protocol                  = "tcp"
  to_port                      = 3000
  description                  = "Forward traffic to application instances"
}

resource "aws_security_group" "bastion" {
  name        = "${var.project}-${var.environment}-bastion-sg"
  description = "Security group for the CloudRecover bastion host"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project}-${var.environment}-bastion-sg"
    Environment = var.environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  description       = "SSH access from administrator IP"
  cidr_ipv4   = var.my_ip
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "bastion_all_outbound" {
  security_group_id = aws_security_group.bastion.id
  description       = "Allow all outbound traffic"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# Prometheus security group
resource "aws_security_group" "prometheus" {
  name        = "${var.project}-${var.environment}-prometheus-sg"
  description = "Controls access to Prometheus monitoring"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project}-${var.environment}-prometheus-sg"
    Project     = var.project
    Environment = var.environment
    Component   = "monitoring"
  }
}

resource "aws_vpc_security_group_ingress_rule" "prometheus_ssh_from_bastion_host" {
  security_group_id = aws_security_group.prometheus.id
  referenced_security_group_id = aws_security_group.bastion.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  description       = "SSH access from the Bastion Host"
}

resource "aws_vpc_security_group_ingress_rule" "prometheus_ui_from_my_ip" {
  security_group_id = aws_security_group.prometheus.id
  cidr_ipv4         = var.my_ip
  from_port         = 9090
  ip_protocol       = "tcp"
  to_port           = 9090
  description       = "Prometheus UI access from the administrator IP"
}

resource "aws_vpc_security_group_ingress_rule" "prometheus_from_grafana" {
  security_group_id            = aws_security_group.prometheus.id
  referenced_security_group_id = aws_security_group.grafana.id
  from_port                    = 9090
  ip_protocol                  = "tcp"
  to_port                      = 9090
  description                  = "Allow Grafana to query Prometheus"
}

resource "aws_vpc_security_group_egress_rule" "prometheus_outbound_ipv4" {
  security_group_id = aws_security_group.prometheus.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow outbound IPv4 traffic"
}

resource "aws_vpc_security_group_egress_rule" "prometheus_outbound_ipv6" {
  security_group_id = aws_security_group.prometheus.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
  description       = "Allow outbound IPv6 traffic"
}


# Grafana security group
resource "aws_security_group" "grafana" {
  name        = "${var.project}-${var.environment}-grafana-sg"
  description = "Controls access to Grafana dashboards"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project}-${var.environment}-grafana-sg"
    Project     = var.project
    Environment = var.environment
    Component   = "monitoring"
  }
}

resource "aws_vpc_security_group_ingress_rule" "grafana_ssh_from_bastion_host" {
  security_group_id = aws_security_group.grafana.id
  referenced_security_group_id = aws_security_group.bastion.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  description       = "SSH access from the Bastion"
}

resource "aws_vpc_security_group_ingress_rule" "grafana_ui_from_my_ip" {
  security_group_id = aws_security_group.grafana.id
  cidr_ipv4         = var.my_ip
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
  description       = "Grafana UI access from the administrator IP"
}

resource "aws_vpc_security_group_egress_rule" "grafana_outbound_ipv4" {
  security_group_id = aws_security_group.grafana.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow outbound IPv4 traffic"
}

resource "aws_vpc_security_group_egress_rule" "grafana_outbound_ipv6" {
  security_group_id = aws_security_group.grafana.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
  description       = "Allow outbound IPv6 traffic"
}


# RDS PostgreSQL security group
resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Controls access to the PostgreSQL database"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project}-${var.environment}-rds-sg"
    Project     = var.project
    Environment = var.environment
    Component   = "database"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_postgresql_from_web" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
  description                  = "PostgreSQL access from application instances"
}
