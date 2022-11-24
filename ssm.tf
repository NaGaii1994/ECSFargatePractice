resource "aws_kms_key" "this" {
  tags = {
    Name = "${var.project_name}_KMS"
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.project_name}"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_ssm_parameter" "POSTGRES_DB" {
  name = "/${var.project_name}/POSTGRES_DB"
  type = "SecureString"
  key_id = aws_kms_key.this.arn
  value = var.POSTGRES_DB
}

resource "aws_ssm_parameter" "POSTGRES_USER" {
  name = "/${var.project_name}/POSTGRES_USER"
  type = "SecureString"
  key_id = aws_kms_key.this.arn
  value = var.POSTGRES_USER
}

resource "aws_ssm_parameter" "POSTGRES_PASSWORD" {
  name = "/${var.project_name}/POSTGRES_PASSWORD"
  type = "SecureString"
  key_id = aws_kms_key.this.arn
  value = var.POSTGRES_PASSWORD
}