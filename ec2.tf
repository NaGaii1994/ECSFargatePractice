resource "aws_instance" "ec2" {
  ami           = "ami-072bfb8ae2c884cc4"
  instance_type = "t2.micro"
  subnet_id=aws_subnet.public_subnet_a.id
  key_name = aws_key_pair.ec2_key_pair.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "${var.project_name}_ec2_instance"
  }
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.project_name}_public_key"
  public_key = file("${var.ssh_public_key}")
}

resource "aws_eip" "ec2" {
  vpc      = true
  instance   = aws_instance.ec2.id
  tags = {
    Name = "${var.project_name}_ec2_eip"
  }
}