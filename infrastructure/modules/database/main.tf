resource "aws_db_subnet_group" "cloudrecover_database" {
  name       = "${var.db_name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.db_name}-subnet-group"
  }
}

resource "aws_db_instance" "cloudrecover_database" {
  identifier             = var.db_name
  allocated_storage      = var.allocated_storage
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  db_name                = var.db_name
  username               = var.username
  password               = var.password
  db_subnet_group_name   = aws_db_subnet_group.cloudrecover_database.name
  vpc_security_group_ids = [var.rds_security_group_id]
  skip_final_snapshot    = true


  tags = {
    Name = var.db_name
  }
}
