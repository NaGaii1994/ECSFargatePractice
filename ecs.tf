data "aws_ssm_parameter" "DJANGO_SECRET_KEY" {
  name = "/${var.project_name}/DJANGO_SECRET_KEY"
  depends_on = [
    aws_ssm_parameter.DJANGO_SECRET_KEY
  ]
}

data "aws_ssm_parameter" "POSTGRES_DB" {
  name = "/${var.project_name}/POSTGRES_DB"
  depends_on = [
    aws_ssm_parameter.POSTGRES_DB
  ]
}

data "aws_ssm_parameter" "POSTGRES_USER" {
  name = "/${var.project_name}/POSTGRES_USER"
  depends_on = [
    aws_ssm_parameter.POSTGRES_USER
  ]
}

data "aws_ssm_parameter" "POSTGRES_PASSWORD" {
  name = "/${var.project_name}/POSTGRES_PASSWORD"
  depends_on = [
    aws_ssm_parameter.POSTGRES_PASSWORD
  ]
}

resource "aws_ecs_task_definition" "main" {
  family = "${var.project_name}"

  # データプレーンの選択
  requires_compatibilities = ["FARGATE"]

  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  # ECSタスクが使用可能なリソースの上限
  # タスク内のコンテナはこの上限内に使用するリソースを収める必要があり、メモリが上限に達した場合OOM Killer にタスクがキルされる
  cpu    = "256"
  memory = "512"

  # ECSタスクのネットワークドライバ
  # Fargateを使用する場合は"awsvpc"決め打ち
  network_mode = "awsvpc"

  # 起動するコンテナの定義
  # 「nginxを起動し、80ポートを開放する」設定を記述。
  container_definitions = jsonencode([
    {
      name             = "nginx"
      image            = "${var.docker_image_url_nginx}"
      portMappings     = [{ containerPort : 80, hostPort: 80}]
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          awslogs-region : "ap-northeast-1"
          awslogs-group : aws_cloudwatch_log_group.nginx.name
          awslogs-stream-prefix : "ecs"
        }
      }
    },
    {
      name             = "django"
      image            = "${var.docker_image_url_django}"
      portMappings     = [{ containerPort : 8000, hostPort: 8000}]
      command = ["gunicorn", "-w", "3", "-b", ":8000", "hello_django.wsgi:application"]
      environment = [
        {
          name: "ALLOWED_HOSTS"
          value: "${var.host_domain}"
        },
        {
          name: "POSTGRES_HOST"
          value: "${aws_db_instance.this.address}"
        },
        {
          name: "POSTGRES_PORT"
          value: "5432"
        }
      ]
      secrets = [
        {
          name: "DJANGO_SECRET_KEY"
          valueFrom: aws_ssm_parameter.DJANGO_SECRET_KEY.arn
        },
        {
          name: "POSTGRES_DB"
          valueFrom: data.aws_ssm_parameter.POSTGRES_DB.arn
        },
        {
          name: "POSTGRES_USER"
          valueFrom: data.aws_ssm_parameter.POSTGRES_USER.arn
        },
        {
          name: "POSTGRES_PASSWORD"
          valueFrom: data.aws_ssm_parameter.POSTGRES_PASSWORD.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          awslogs-region : "ap-northeast-1"
          awslogs-group : aws_cloudwatch_log_group.django.name
          awslogs-stream-prefix : "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}"
}

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}"
  description = "ECS SG for ${var.project_name}."

  # セキュリティグループを配置するVPC
  vpc_id      = "${aws_vpc.vpc.id}"

  # セキュリティグループ内のリソースからインターネットへのアクセス許可設定
  # 今回の場合DockerHubへのPullに使用する。
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}"
  }
}

resource "aws_security_group_rule" "ecs" {
  security_group_id = "${aws_security_group.ecs.id}"

  # インターネットからセキュリティグループ内のリソースへのアクセス許可設定
  type = "ingress"

  # TCPでの80ポートへのアクセスを許可する
  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  # 同一VPC内からのアクセスのみ許可
  cidr_blocks = ["10.0.0.0/16"]
}

resource "aws_ecs_service" "main" {
  name = "${var.project_name}"

  # 依存関係の記述。
  # "aws_lb_listener_rule.to_nginx" リソースの作成が完了するのを待ってから当該リソースの作成を開始する。
  # "depends_on" は "aws_ecs_service" リソース専用のプロパティではなく、Terraformのシンタックスのため他の"resource"でも使用可能
  depends_on = [aws_lb_listener_rule.to_nginx]

  # 当該ECSサービスを配置するECSクラスターの指定
  cluster = "${aws_ecs_cluster.main.name}"

  # データプレーンとしてFargateを使用する
  launch_type = "FARGATE"

  # ECSタスクの起動数を定義
  desired_count = "1"

  # 起動するECSタスクのタスク定義
  task_definition = "${aws_ecs_task_definition.main.arn}"

  # ECSタスクへ設定するネットワークの設定
  network_configuration {
    # タスクの起動を許可するサブネット
    subnets         = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_c.id}"]
    # タスクに紐付けるセキュリティグループ
    security_groups = ["${aws_security_group.ecs.id}"]
  }

  # ECSタスクの起動後に紐付けるELBターゲットグループ
  load_balancer {
    target_group_arn = "${aws_lb_target_group.to_nginx.arn}"
    container_name   = "nginx"
    container_port   = "80"
  }
}

resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/ecs/${var.project_name}/nginx"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "django" {
  name              = "/ecs/${var.project_name}/django"
  retention_in_days = 30
}