data "aws_route53_zone" "selected" {
  name = "${var.host_domain}"
}

resource "aws_route53_record" "web" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${data.aws_route53_zone.selected.name}"
  type    = "A"

  alias {
    name                   = "${aws_lb.this.dns_name}"
    zone_id                = "${aws_lb.this.zone_id}"
    evaluate_target_health = true
  }
}