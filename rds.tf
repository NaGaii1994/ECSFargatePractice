resource "aws_security_group" "rds" {
  name        = "rds-security-group"
  description = "Allows inbound access from ECS only"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = "5432"
    to_port         = "5432"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "this" {
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_c.id]
  tags = {
    Name = "${var.project_name}"
  }
}

resource "aws_db_instance" "this" {
  identifier              = "production"
  db_name                 = var.POSTGRES_DB
  username                = var.POSTGRES_USER
  password                = var.POSTGRES_PASSWORD
  port                    = "5432"
  engine                  = "postgres"
  engine_version          = "12"
  instance_class          = var.rds_instance_class
  allocated_storage       = "20"
  storage_encrypted       = false
  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.this.name
  multi_az                = false
  storage_type            = "gp2"
  publicly_accessible     = false
  backup_retention_period = 7
  skip_final_snapshot     = true
}