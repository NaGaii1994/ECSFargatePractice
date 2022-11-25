resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
}

resource "aws_iam_role_policy" "kms_decrypt_policy" {
  name = "${var.project_name}_ecs_task_execution_role_policy_kms"
  role               = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
        "Action": [
          "kms:Decrypt"
        ],
        "Resource": [
          data.aws_ssm_parameter.DJANGO_SECRET_KEY.arn,
          data.aws_ssm_parameter.POSTGRES_DB.arn,
          data.aws_ssm_parameter.POSTGRES_USER.arn,
          data.aws_ssm_parameter.POSTGRES_PASSWORD.arn,
          aws_kms_key.this.arn
        ]
      }
    ]
  })
  depends_on = [
    data.aws_ssm_parameter.DJANGO_SECRET_KEY,
    data.aws_ssm_parameter.POSTGRES_DB,
    data.aws_ssm_parameter.POSTGRES_USER,
    data.aws_ssm_parameter.POSTGRES_PASSWORD
  ]
}