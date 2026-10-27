variable "region" {
  description = "AWS region where the networking infrastructure will be deployed"
  type        = string
}

variable "availability_zone_1" {
  description = "First Availability Zone for subnet deployment"
  type        = string
}

variable "availability_zone_2" {
  description = "Second Availability Zone for subnet deployment"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for the first public subnet"
  type        = string
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for the second public subnet"
  type        = string
}

variable "app_subnet_1_cidr" {
  description = "CIDR block for the first application subnet"
  type        = string
}

variable "app_subnet_2_cidr" {
  description = "CIDR block for the second application subnet"
  type        = string
}

variable "monitoring_subnet_1_cidr" {
  description = "CIDR block for the first monitoring subnet"
  type        = string
}

variable "monitoring_subnet_2_cidr" {
  description = "CIDR block for the second monitoring subnet"
  type        = string
}

variable "database_subnet_1_cidr" {
  description = "CIDR block for the first database subnet"
  type        = string
}

variable "database_subnet_2_cidr" {
  description = "CIDR block for the second database subnet"
  type        = string
}

variable "public_route_cidr" {
  description = "Destination CIDR block for the public default route"
  type        = string
}

variable "private_route_1_cidr" {
  description = "Destination CIDR block for the first private default route"
  type        = string
}

variable "private_route_2_cidr" {
  description = "Destination CIDR block for the second private default route"
  type        = string
}

variable "public_subnet_1_name" {
  description = "Name tag for the first public subnet"
  type        = string
}

variable "public_subnet_2_name" {
  description = "Name tag for the second public subnet"
  type        = string
}

variable "app_subnet_1_name" {
  description = "Name tag for the first application subnet"
  type        = string
}

variable "app_subnet_2_name" {
  description = "Name tag for the second application subnet"
  type        = string
}

variable "monitoring_subnet_1_name" {
  description = "Name tag for the first monitoring subnet"
  type        = string
}

variable "monitoring_subnet_2_name" {
  description = "Name tag for the second monitoring subnet"
  type        = string
}

variable "database_subnet_1_name" {
  description = "Name tag for the first database subnet"
  type        = string
}

variable "database_subnet_2_name" {
  description = "Name tag for the second database subnet"
  type        = string
}

variable "internet_gateway_name" {
  description = "Name tag for the internet gateway"
  type        = string
}

variable "nat_gateway_1_eip_name" {
  description = "Name tag for the first NAT gateway Elastic IP"
  type        = string
}

variable "nat_gateway_2_eip_name" {
  description = "Name tag for the second NAT gateway Elastic IP"
  type        = string
}

variable "nat_gateway_1_name" {
  description = "Name tag for the first NAT gateway"
  type        = string
}

variable "nat_gateway_2_name" {
  description = "Name tag for the second NAT gateway"
  type        = string
}

variable "public_route_table_name" {
  description = "Name tag for the public route table"
  type        = string
}

variable "private_route_table_1_name" {
  description = "Name tag for the first private route table"
  type        = string
}

variable "private_route_table_2_name" {
  description = "Name tag for the second private route table"
  type        = string
}

variable "database_route_table_name" {
  description = "Name tag for the database route table"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Whether to provision NAT Gateways"
  type        = bool
  default     = true
}
