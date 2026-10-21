resource "aws_instance"  "app-server"  {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  security_groups = [var.app_server_security_group_id]

    root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
  tags = {
    Name = var.instance_name
  }
}
