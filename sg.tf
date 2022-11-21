resource "aws_security_group" "ec2_sg" {
  name   = "${var.project_name}_ec2_sg"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}_ec2_sg"
  }
}

resource "aws_security_group_rule" "ec2_sg_out_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_sg.id
}

resource "aws_security_group_rule" "ec2_sg_in_http" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_sg.id
}