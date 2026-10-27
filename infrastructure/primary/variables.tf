
# ==========================================
# Project Configuration
# ==========================================

variable "project" {
  description = "Project name used for resource naming"
  type        = string
  default     = "cloudrecover"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "primary"

  validation {
    condition     = contains(["primary", "recovery"], var.environment)
    error_message = "Environment must be primary or recovery."
  }
}

# ==========================================
# AWS Region and Availability Zones
# ==========================================

variable "region" {
  description = "AWS region for the primary environment"
  type        = string
}

variable "availability_zone_1" {
  description = "First Availability Zone"
  type        = string
}

variable "availability_zone_2" {
  description = "Second Availability Zone"
  type        = string
}

# ==========================================
# VPC Configuration
# ==========================================

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

# ==========================================
# Public Subnet Configuration
# ==========================================

variable "public_subnet_1_cidr" {
  description = "First public subnet CIDR"
  type        = string
}

variable "public_subnet_2_cidr" {
  description = "Second public subnet CIDR"
  type        = string
}

# ==========================================
# Application Subnet Configuration
# ==========================================

variable "app_subnet_1_cidr" {
  description = "First application subnet CIDR"
  type        = string
}

variable "app_subnet_2_cidr" {
  description = "Second application subnet CIDR"
  type        = string
}

# ==========================================
# Monitoring Subnet Configuration
# ==========================================

variable "monitoring_subnet_1_cidr" {
  description = "First monitoring subnet CIDR"
  type        = string
}

variable "monitoring_subnet_2_cidr" {
  description = "Second monitoring subnet CIDR"
  type        = string
}

# ==========================================
# Database Subnet Configuration
# ==========================================

variable "database_subnet_1_cidr" {
  description = "First database subnet CIDR"
  type        = string
}

variable "database_subnet_2_cidr" {
  description = "Second database subnet CIDR"
  type        = string
}

# ==========================================
# Route Configuration
# ==========================================

variable "public_route_cidr" {
  description = "Public default route destination"
  type        = string
}

variable "private_route_1_cidr" {
  description = "First private default route destination"
  type        = string
}

variable "private_route_2_cidr" {
  description = "Second private default route destination"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Whether to provision NAT Gateways for private subnet outbound internet access"
  type        = bool
  default     = true
}

# ==========================================
# Subnet Resource Names
# ==========================================

variable "public_subnet_1_name" {
  description = "First public subnet name"
  type        = string
}

variable "public_subnet_2_name" {
  description = "Second public subnet name"
  type        = string
}

variable "app_subnet_1_name" {
  description = "First application subnet name"
  type        = string
}

variable "app_subnet_2_name" {
  description = "Second application subnet name"
  type        = string
}

variable "monitoring_subnet_1_name" {
  description = "First monitoring subnet name"
  type        = string
}

variable "monitoring_subnet_2_name" {
  description = "Second monitoring subnet name"
  type        = string
}

variable "database_subnet_1_name" {
  description = "First database subnet name"
  type        = string
}

variable "database_subnet_2_name" {
  description = "Second database subnet name"
  type        = string
}

# ==========================================
# Internet Gateway
# ==========================================

variable "internet_gateway_name" {
  description = "Internet gateway name"
  type        = string
}

# ==========================================
# NAT Gateways and Elastic IPs
# ==========================================

variable "nat_gateway_1_eip_name" {
  description = "First NAT gateway Elastic IP name"
  type        = string
}

variable "nat_gateway_2_eip_name" {
  description = "Second NAT gateway Elastic IP name"
  type        = string
}

variable "nat_gateway_1_name" {
  description = "First NAT gateway name"
  type        = string
}

variable "nat_gateway_2_name" {
  description = "Second NAT gateway name"
  type        = string
}

# ==========================================
# Route Table Names
# ==========================================

variable "public_route_table_name" {
  description = "Public route table name"
  type        = string
}

variable "private_route_table_1_name" {
  description = "First private route table name"
  type        = string
}

variable "private_route_table_2_name" {
  description = "Second private route table name"
  type        = string
}

variable "database_route_table_name" {
  description = "Database route table name"
  type        = string
}

# ==========================================
# Administrator Access
# ==========================================

variable "my_ip" {
  description = "Administrator public IPv4 CIDR, such as 203.0.113.10/32"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.my_ip))
    error_message = "Provide a valid IPv4 CIDR, such as 203.0.113.10/32."
  }
}

# ==========================================
# Application EC2 Configuration
# ==========================================

variable "ami_id" {
  description = "Ubuntu AMI ID valid in the deployment region"
  type        = string
}

variable "app_instance_name" {
  description = "Name of the application EC2 instance"
  type        = string
  default     = "web01"
}

variable "app_instance_type" {
  description = "EC2 instance type for the application server"
  type        = string
  default     = "c7i-flex.large"
}

# ==========================================
# Monitoring EC2 Configuration
# ==========================================

variable "monitoring_instance_type" {
  description = "EC2 instance type for monitoring servers"
  type        = string
  default     = "t3.small"
}

# ==========================================
# Bastion EC2 Configuration
# ==========================================

variable "key_name" {
  description = "Name of the SSH key pair for the bastion host"
  type        = string
}

variable "public_key_path" {
  description = "Path to the SSH public key file for the bastion host"
  type        = string
}

variable "app_public_key_path" {
  description = "Path to the SSH public key file for the application server"
  type        = string
}

variable "prometheus_public_key_path" {
  description = "Path to the SSH public key file for the Prometheus server"
  type        = string
}

variable "grafana_public_key_path" {
  description = "Path to the SSH public key file for the Grafana server"
  type        = string
}

# ==========================================
# RDS Database Credentials
# ==========================================

variable "db_username" {
  description = "RDS master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}
