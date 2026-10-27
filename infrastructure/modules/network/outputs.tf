output "vpc_id" {
  description = "ID of the CloudRecover VPC"
  value       = aws_vpc.cloud-recover.id
}

output "public_subnet_az1_id" {
  description = "ID of the public subnet in Availability Zone 1"
  value       = aws_subnet.cloud-recover-pub-1.id
}

output "public_subnet_az2_id" {
  description = "ID of the public subnet in Availability Zone 2"
  value       = aws_subnet.cloud-recover-pub-2.id
}

output "app_subnet_az1_id" {
  description = "ID of the application subnet in Availability Zone 1"
  value       = aws_subnet.cloud-recover-app-1.id
}

output "app_subnet_az2_id" {
  description = "ID of the application subnet in Availability Zone 2"
  value       = aws_subnet.cloud-recover-app-2.id
}

output "monitoring_subnet_az1_id" {
  description = "ID of the monitoring subnet in Availability Zone 1"
  value       = aws_subnet.cloud-recover-monitoring-1.id
}

output "monitoring_subnet_az2_id" {
  description = "ID of the monitoring subnet in Availability Zone 2"
  value       = aws_subnet.cloud-recover-monitoring-2.id
}

output "database_subnet_az1_id" {
  description = "ID of the database subnet in Availability Zone 1"
  value       = aws_subnet.cloud-recover-database_subnet-1.id
}

output "database_subnet_az2_id" {
  description = "ID of the database subnet in Availability Zone 2"
  value       = aws_subnet.cloud-recover-database_subnet-2.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway attached to the CloudRecover VPC"
  value       = aws_internet_gateway.cloud-recover-IGW.id
}

output "nat_gateway_az1_eip_id" {
  description = "ID of the Elastic IP allocated to NAT Gateway 1"
  value       = var.enable_nat_gateway ? aws_eip.nat-1[0].id : null
}

output "nat_gateway_az2_eip_id" {
  description = "ID of the Elastic IP allocated to NAT Gateway 2"
  value       = var.enable_nat_gateway ? aws_eip.nat-2[0].id : null
}

output "nat_gateway_az1_id" {
  description = "ID of NAT Gateway 1 for outbound internet access"
  value       = var.enable_nat_gateway ? aws_nat_gateway.cloud-recover-web-monit-NGW-1[0].id : null
}

output "nat_gateway_az2_id" {
  description = "ID of NAT Gateway 2 for outbound internet access"
  value       = var.enable_nat_gateway ? aws_nat_gateway.cloud-recover-web-monit-NGW-2[0].id : null
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.cloud-recover-pub-RT.id
}

output "private_route_table_1_id" {
  description = "ID of the first private route table"
  value       = aws_route_table.cloud-recover-priv-RT-1.id
}

output "private_route_table_2_id" {
  description = "ID of the second private route table"
  value       = aws_route_table.cloud-recover-priv-RT-2.id
}

output "database_route_table_id" {
  description = "ID of the database route table"
  value       = aws_route_table.cloud-recover-db-RT.id
}

output "public_subnet_1_route_table_association_id" {
  description = "ID of the route table association for public subnet 1"
  value       = aws_route_table_association.cloud-recoverpub-1-a.id
}

output "public_subnet_2_route_table_association_id" {
  description = "ID of the route table association for public subnet 2"
  value       = aws_route_table_association.cloud-recoverpub-1-b.id
}

output "app_subnet_1_route_table_association_id" {
  description = "ID of the route table association for application subnet 1"
  value       = aws_route_table_association.cloud-recover-app-1-a.id
}

output "app_subnet_2_route_table_association_id" {
  description = "ID of the route table association for application subnet 2"
  value       = aws_route_table_association.cloud-recover-app-1-b.id
}

output "monitoring_subnet_1_route_table_association_id" {
  description = "ID of the route table association for monitoring subnet 1"
  value       = aws_route_table_association.cloud-recover-monitoring-1-a.id
}

output "monitoring_subnet_2_route_table_association_id" {
  description = "ID of the route table association for monitoring subnet 2"
  value       = aws_route_table_association.cloud-recover-monitoring-1-b.id
}

output "database_subnet_1_route_table_association_id" {
  description = "ID of the route table association for database subnet 1"
  value       = aws_route_table_association.cloud-recover-database-1-a.id
}

output "database_subnet_2_route_table_association_id" {
  description = "ID of the route table association for database subnet 2"
  value       = aws_route_table_association.cloud-recover-database-1-b.id
}
