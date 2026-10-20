resource "aws_vpc" "cloud-recover" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "cloud-recover-pub-1" {
  vpc_id                  = aws_vpc.cloud-recover.id
  cidr_block              = var.public_subnet_1_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone_1
  tags = {
    Name = var.public_subnet_1_name
  }
}

resource "aws_subnet" "cloud-recover-pub-2" {
  vpc_id                  = aws_vpc.cloud-recover.id
  cidr_block              = var.public_subnet_2_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone_2
  tags = {
    Name = var.public_subnet_2_name
  }
}

resource "aws_subnet" "cloud-recover-app-1" {
  vpc_id                  = aws_vpc.cloud-recover.id
  cidr_block              = var.app_subnet_1_cidr
  map_public_ip_on_launch = "false"
  availability_zone       = var.availability_zone_1
  tags = {
    Name = var.app_subnet_1_name
  }
}

resource "aws_subnet" "cloud-recover-app-2" {
  vpc_id                  = aws_vpc.cloud-recover.id
  cidr_block              = var.app_subnet_2_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone_2
  tags = {
    Name = var.app_subnet_2_name
  }
}

resource "aws_subnet" "cloud-recover-monitoring-1" {
  vpc_id                  = aws_vpc.cloud-recover.id
  cidr_block              = var.monitoring_subnet_1_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone_1
  tags = {
    Name = var.monitoring_subnet_1_name
  }
}

resource "aws_subnet" "cloud-recover-monitoring-2" {
  vpc_id                  = aws_vpc.cloud-recover.id
  cidr_block              = var.monitoring_subnet_2_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone_2
  tags = {
    Name = var.monitoring_subnet_2_name
  }
}

resource "aws_subnet" "cloud-recover-database_subnet-1" {
  vpc_id                  = aws_vpc.cloud-recover.id
  cidr_block              = var.database_subnet_1_cidr
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zone_1
  tags = {
    Name = var.database_subnet_1_name
  }
}


resource "aws_subnet" "cloud-recover-database_subnet-2" {
  vpc_id                  = aws_vpc.cloud-recover.id
  cidr_block              = var.database_subnet_2_cidr
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zone_2
  tags = {
    Name = var.database_subnet_2_name
  }
}


resource "aws_internet_gateway" "cloud-recover-IGW" {
  vpc_id = aws_vpc.cloud-recover.id
  tags = {
    Name = var.internet_gateway_name
  }
}

resource "aws_eip" "nat-1" {
  domain = "vpc"

  tags = {
    Name = var.nat_gateway_1_eip_name
  }
}

resource "aws_eip" "nat-2" {
  domain = "vpc"

  tags = {
    Name = var.nat_gateway_2_eip_name
  }
}


resource "aws_nat_gateway" "cloud-recover-web-monit-NGW-1" {
  allocation_id = aws_eip.nat-1.id
  subnet_id     = aws_subnet.cloud-recover-pub-1.id
  tags = {
    Name = var.nat_gateway_1_name
  }
  depends_on = [aws_internet_gateway.cloud-recover-IGW]
}

resource "aws_nat_gateway" "cloud-recover-web-monit-NGW-2" {
  allocation_id = aws_eip.nat-2.id
  subnet_id     = aws_subnet.cloud-recover-pub-2.id
  tags = {
    Name = var.nat_gateway_2_name
  }
  depends_on = [aws_internet_gateway.cloud-recover-IGW]
}

resource "aws_route_table" "cloud-recover-pub-RT" {
  vpc_id = aws_vpc.cloud-recover.id

  route {
    cidr_block = var.public_route_cidr
    gateway_id = aws_internet_gateway.cloud-recover-IGW.id
  }

  tags = {
    Name = var.public_route_table_name
  }
}

resource "aws_route_table" "cloud-recover-priv-RT-1" {
  vpc_id = aws_vpc.cloud-recover.id

  route {
    cidr_block     = var.private_route_1_cidr
    nat_gateway_id = aws_nat_gateway.cloud-recover-web-monit-NGW-1.id
  }

  tags = {
    Name = var.private_route_table_1_name
  }
}

resource "aws_route_table" "cloud-recover-priv-RT-2" {
  vpc_id = aws_vpc.cloud-recover.id

  route {
    cidr_block     = var.private_route_2_cidr
    nat_gateway_id = aws_nat_gateway.cloud-recover-web-monit-NGW-2.id
  }

  tags = {
    Name = var.private_route_table_2_name
  }
}

resource "aws_route_table" "cloud-recover-db-RT" {
  vpc_id = aws_vpc.cloud-recover.id

  tags = {
    Name = var.database_route_table_name
  }
}



resource "aws_route_table_association" "cloud-recoverpub-1-a" {
  subnet_id      = aws_subnet.cloud-recover-pub-1.id
  route_table_id = aws_route_table.cloud-recover-pub-RT.id
}

resource "aws_route_table_association" "cloud-recoverpub-1-b" {
  subnet_id      = aws_subnet.cloud-recover-pub-2.id
  route_table_id = aws_route_table.cloud-recover-pub-RT.id
}

resource "aws_route_table_association" "cloud-recover-app-1-a" {
  subnet_id      = aws_subnet.cloud-recover-app-1.id
  route_table_id = aws_route_table.cloud-recover-priv-RT-1.id
}

resource "aws_route_table_association" "cloud-recover-app-1-b" {
  subnet_id      = aws_subnet.cloud-recover-app-2.id
  route_table_id = aws_route_table.cloud-recover-priv-RT-2.id
}

resource "aws_route_table_association" "cloud-recover-monitoring-1-a" {
  subnet_id      = aws_subnet.cloud-recover-monitoring-1.id
  route_table_id = aws_route_table.cloud-recover-priv-RT-1.id
}

resource "aws_route_table_association" "cloud-recover-monitoring-1-b" {
  subnet_id      = aws_subnet.cloud-recover-monitoring-2.id
  route_table_id = aws_route_table.cloud-recover-priv-RT-2.id
}

resource "aws_route_table_association" "cloud-recover-database-1-a" {
  subnet_id      = aws_subnet.cloud-recover-database_subnet-1.id
  route_table_id = aws_route_table.cloud-recover-db-RT.id
}

resource "aws_route_table_association" "cloud-recover-database-1-b" {
  subnet_id      = aws_subnet.cloud-recover-database_subnet-2.id
  route_table_id = aws_route_table.cloud-recover-db-RT.id
}


# Default instance tenancy determines whether EC2 instances launched into your VPC run on shared hardware or dedicated hardware.