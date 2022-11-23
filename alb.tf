resource "aws_security_group" "alb" {
  name = "${var.project_name}-integrated-alb"
  description = "${var.project_name} alb rule based routing"
  vpc_id = aws_vpc.vpc.id
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}-integrated-alb"
  }
}

resource "aws_security_group_rule" "alb_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  to_port           = 80
  type              = "ingress"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_https" {
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  to_port           = 443
  type              = "ingress"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "this" {
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.alb.id
  ]
  subnets = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_c.id,
  ]
  tags = {
    Name = "${var.project_name}-integrated-alb"
  }
}

resource "aws_lb_target_group" "to_nginx" {
  name = "${var.project_name}"

  # ターゲットグループを作成するVPC
  vpc_id = "${aws_vpc.vpc.id}"

  # ALBからECSタスクのコンテナへトラフィックを振り分ける設定
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"

  # コンテナへの死活監視設定
  health_check {
    port = 80
    path = "/"
  }
}

resource "aws_lb_listener_rule" "to_nginx" {
  # ルールを追加するリスナー
  listener_arn = "${aws_lb_listener.https.arn}"

  # 受け取ったトラフィックをターゲットグループへ受け渡す
  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.to_nginx.id}"
  }

  # ターゲットグループへ受け渡すトラフィックの条件
  condition {
    host_header {
      values = [var.host_domain]
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port = 443
  protocol = "HTTPS"
  certificate_arn = "${aws_acm_certificate.cert.arn}"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Success!!!"
      status_code = "200"
    }
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}