resource "aws_instance" "ec2" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_az1.id
  key_name      = var.key_name
  vpc_security_group_ids = var.security_group_ids
}

tags   = {
    Name = "my-jenkins-server"
  }
