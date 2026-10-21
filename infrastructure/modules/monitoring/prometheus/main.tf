resource "aws_instance"  "prometheus-server"  {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id = var.subnet_id

  security_groups = [var.prometheus_security_group_id]
  tags = {
    Name = var.instance_name
  }
}

resource "aws_ec2_instance_state" "prometheus-server-state" {
  instance_id = aws_instance.prometheus-server.id
  state       = "running"
}
