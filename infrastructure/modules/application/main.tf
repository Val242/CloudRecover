resource "aws_instance"  "app-server"  {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = aws_key_pair.cloudrecover-private-server.key_name
  vpc_security_group_ids = [ var.app_server_security_group_id ]

    root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
  tags = {
    Name = var.instance_name
  }
}

resource "aws_ec2_instance_state" "app-server-state" {
  instance_id = aws_instance.app-server.id
  state       = "running"
}

resource "aws_key_pair" "cloudrecover-private-server" {
  key_name   = var.key_name
  public_key = file(pathexpand(var.app_public_key_path))

  tags = {
    Name        = var.key_name
    Environment = var.environment
  }
}
