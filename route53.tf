data "aws_route53_zone" "selected" {
  name = "${var.host_domain}"
}

resource "aws_route53_record" "web" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.ec2.public_ip]
}