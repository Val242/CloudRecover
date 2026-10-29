module "vpc" {
  source = "../modules/network"

  enable_nat_gateway = var.enable_nat_gateway

  # AWS Region and Availability Zones
  region              = var.region
  availability_zone_1 = var.availability_zone_1
  availability_zone_2 = var.availability_zone_2

  # VPC Configuration
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr

  # Public Subnets
  public_subnet_1_cidr = var.public_subnet_1_cidr
  public_subnet_2_cidr = var.public_subnet_2_cidr

  # Application Subnets
  app_subnet_1_cidr = var.app_subnet_1_cidr
  app_subnet_2_cidr = var.app_subnet_2_cidr

  # Monitoring Subnets
  monitoring_subnet_1_cidr = var.monitoring_subnet_1_cidr
  monitoring_subnet_2_cidr = var.monitoring_subnet_2_cidr

  # Database Subnets
  database_subnet_1_cidr = var.database_subnet_1_cidr
  database_subnet_2_cidr = var.database_subnet_2_cidr

  # Route CIDRs
  public_route_cidr    = var.public_route_cidr
  private_route_1_cidr = var.private_route_1_cidr
  private_route_2_cidr = var.private_route_2_cidr

  # Public Subnet Names
  public_subnet_1_name = var.public_subnet_1_name
  public_subnet_2_name = var.public_subnet_2_name

  # Application Subnet Names
  app_subnet_1_name = var.app_subnet_1_name
  app_subnet_2_name = var.app_subnet_2_name

  # Monitoring Subnet Names
  monitoring_subnet_1_name = var.monitoring_subnet_1_name
  monitoring_subnet_2_name = var.monitoring_subnet_2_name

  # Database Subnet Names
  database_subnet_1_name = var.database_subnet_1_name
  database_subnet_2_name = var.database_subnet_2_name

  # Internet Gateway
  internet_gateway_name = var.internet_gateway_name

  # NAT Gateway Elastic IPs
  nat_gateway_1_eip_name = var.nat_gateway_1_eip_name
  nat_gateway_2_eip_name = var.nat_gateway_2_eip_name

  # NAT Gateways
  nat_gateway_1_name = var.nat_gateway_1_name
  nat_gateway_2_name = var.nat_gateway_2_name

  # Route Tables
  public_route_table_name    = var.public_route_table_name
  private_route_table_1_name = var.private_route_table_1_name
  private_route_table_2_name = var.private_route_table_2_name
  database_route_table_name  = var.database_route_table_name
}

module "security_groups" {
  source = "../modules/security"

  vpc_id      = module.vpc.vpc_id
  my_ip       = var.my_ip
  project     = var.project
  environment = var.environment
}

module "bastion" {
  source                    = "../modules/bastion-host"
  subnet_id                 = module.vpc.public_subnet_az1_id
  bastion_security_group_id = module.security_groups.bastion_security_group_id
  instance_type             = var.app_instance_type
  instance_name             = "Bastion Host"
  ami_id                    = var.ami_id
  key_name                  = var.key_name
  project                   = var.project
  environment               = var.environment
  public_key_path           = var.public_key_path
}

module "load_balancer" {
  source = "../modules/load-balancer"

  alb_name          = "${var.project}-${var.environment}-alb"
  # Keep the existing application target group name to avoid replacing it.
  app_target_group_name        = "${var.project}-${var.environment}-tg"
  prometheus_target_group_name = "${var.project}-${var.environment}-prom-tg"
  grafana_target_group_name    = "${var.project}-${var.environment}-grafana-tg"
  public_subnet_ids = [
    module.vpc.public_subnet_az1_id,
    module.vpc.public_subnet_az2_id
  ]
  app_instance_ids        = [module.app_server.app_server_instance_id]
  prometheus_instance_ids = [module.prometheus_server.prometheus_server_instance_id]
  grafana_instance_ids    = [module.grafana_server.grafana_server_instance_id]
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  alb_security_group_id = module.security_groups.alb_security_group_id
}



module "app_server" {
  source = "../modules/application"

  instance_name = var.app_instance_name
  ami_id        = var.ami_id
  instance_type = var.app_instance_type
  subnet_id     = module.vpc.app_subnet_az1_id
  app_server_security_group_id = module.security_groups.web_security_group_id
  key_name      = "${var.project}-${var.environment}-app-key"
  app_public_key_path = var.app_public_key_path
  environment   = var.environment
}




module "database" {
  source = "../modules/database"

  username = var.db_username
  password = var.db_password
  subnet_ids = [
    module.vpc.database_subnet_az1_id,
    module.vpc.database_subnet_az2_id
  ]
  vpc_id                = module.vpc.vpc_id
  rds_security_group_id = module.security_groups.rds_security_group_id
  snapshot_identifier = "${var.project}-primary-snapshot"
}
