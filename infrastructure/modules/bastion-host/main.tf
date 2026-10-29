resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = aws_key_pair.bastion.key_name
  vpc_security_group_ids = [var.bastion_security_group_id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = var.instance_name
  }
}

resource "aws_ec2_instance_state" "bastion_state" {
  instance_id = aws_instance.bastion.id
  state       = "running"
}

resource "aws_key_pair" "bastion" {
  key_name   = var.key_name
  public_key = file(pathexpand(var.public_key_path))

  tags = {
    Name        = var.key_name
    Environment = var.environment
  }
}
