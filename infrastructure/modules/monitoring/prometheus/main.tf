resource "aws_instance"  "prometheus-server"  {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  key_name = aws_key_pair.cloudrecover-private-server.key_name

  vpc_security_group_ids = [ var.prometheus_security_group_id ]
  tags = {
    Name = var.instance_name
  }
}

resource "aws_ec2_instance_state" "prometheus-server-state" {
  instance_id = aws_instance.prometheus-server.id
  state       = "stopped"
}

resource "aws_key_pair" "cloudrecover-private-server" {
  key_name   = var.key_name
  public_key = file(pathexpand(var.prometheus_public_key_path))

  tags = {
    Name        = var.key_name
    Environment = var.environment
  }
}
