variable "region" {
  description = "AWS region where the networking infrastructure will be deployed"
  type        = string
  default     = "eu-west-1"
}

variable "ZONE1" {
  description = "First Availability Zone for subnet deployment"
  type        = string
  default     = "eu-west-1a"
}

variable "ZONE2" {
  description = "Second Availability Zone for subnet deployment"
  type        = string
  default     = "eu-west-1b"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "Cloud recovery"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "172.40.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for the first public subnet"
  type        = string
  default     = "172.40.10.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for the second public subnet"
  type        = string
  default     = "172.40.11.0/24"
}

variable "app_subnet_1_cidr" {
  description = "CIDR block for the first application subnet"
  type        = string
  default     = "172.40.20.0/24"
}

variable "app_subnet_2_cidr" {
  description = "CIDR block for the second application subnet"
  type        = string
  default     = "172.40.21.0/24"
}

variable "monitoring_subnet_1_cidr" {
  description = "CIDR block for the first monitoring subnet"
  type        = string
  default     = "172.40.30.0/24"
}

variable "monitoring_subnet_2_cidr" {
  description = "CIDR block for the second monitoring subnet"
  type        = string
  default     = "172.40.31.0/24"
}

variable "database_subnet_1_cidr" {
  description = "CIDR block for the first database subnet"
  type        = string
  default     = "172.40.40.0/24"
}

variable "database_subnet_2_cidr" {
  description = "CIDR block for the second database subnet"
  type        = string
  default     = "172.40.41.0/24"
}

variable "public_route_cidr" {
  description = "Destination CIDR block for the public default route"
  type        = string
  default     = "0.0.0.0/0"
}

variable "private_route_1_cidr" {
  description = "Destination CIDR block for the first private default route"
  type        = string
  default     = "0.0.0.0/0"
}

variable "private_route_2_cidr" {
  description = "Destination CIDR block for the second private default route"
  type        = string
  default     = "0.0.0.0/0"
}

variable "public_subnet_1_name" {
  description = "Name tag for the first public subnet"
  type        = string
  default     = "cloud-recover-pub-1"
}

variable "public_subnet_2_name" {
  description = "Name tag for the second public subnet"
  type        = string
  default     = "cloud-recover-pub-2"
}

variable "app_subnet_1_name" {
  description = "Name tag for the first application subnet"
  type        = string
  default     = "cloud-recover-app-1"
}

variable "app_subnet_2_name" {
  description = "Name tag for the second application subnet"
  type        = string
  default     = "cloud-recover-app-2"
}

variable "monitoring_subnet_1_name" {
  description = "Name tag for the first monitoring subnet"
  type        = string
  default     = "cloud-recover-monitoring-1"
}

variable "monitoring_subnet_2_name" {
  description = "Name tag for the second monitoring subnet"
  type        = string
  default     = "cloud-recover-monitoring-2"
}

variable "database_subnet_1_name" {
  description = "Name tag for the first database subnet"
  type        = string
  default     = "cloud-recover-priv-1"
}

variable "database_subnet_2_name" {
  description = "Name tag for the second database subnet"
  type        = string
  default     = "cloud-recover-priv-2"
}

variable "internet_gateway_name" {
  description = "Name tag for the internet gateway"
  type        = string
  default     = "cloud-recover-IGW"
}

variable "nat_gateway_1_eip_name" {
  description = "Name tag for the first NAT gateway Elastic IP"
  type        = string
  default     = "nat-gateway-1-eip"
}

variable "nat_gateway_2_eip_name" {
  description = "Name tag for the second NAT gateway Elastic IP"
  type        = string
  default     = "nat-gateway-2-eip"
}

variable "nat_gateway_1_name" {
  description = "Name tag for the first NAT gateway"
  type        = string
  default     = "cloud-recover-NGW-1"
}

variable "nat_gateway_2_name" {
  description = "Name tag for the second NAT gateway"
  type        = string
  default     = "cloud-recover-NGW-2"
}

variable "public_route_table_name" {
  description = "Name tag for the public route table"
  type        = string
  default     = "cloud-recover-pub-RT"
}

variable "private_route_table_1_name" {
  description = "Name tag for the first private route table"
  type        = string
  default     = "cloud-recover-priv-RT"
}

variable "private_route_table_2_name" {
  description = "Name tag for the second private route table"
  type        = string
  default     = "cloud-recover-priv-RT"
}

variable "database_route_table_name" {
  description = "Name tag for the database route table"
  type        = string
  default     = "cloud-recover-db-RT"
}