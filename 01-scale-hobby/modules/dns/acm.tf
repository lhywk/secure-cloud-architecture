# ACM 인증서 (ap-northeast-2 — ALB용)
# 도메인 없으면 생성 생략
resource "aws_acm_certificate" "alb" {
  count = var.domain_name != "" ? 1 : 0

  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-acm-alb"
  })
}

# DNS 검증 레코드 — 도메인 있을 때만 생성
resource "aws_route53_record" "acm_validation" {
  for_each = var.hosted_zone_id != "" && length(aws_acm_certificate.alb) > 0 ? {
    for dvo in aws_acm_certificate.alb[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# ACM 검증 완료 대기 — 도메인 있을 때만
resource "aws_acm_certificate_validation" "alb" {
  count = var.hosted_zone_id != "" && length(aws_acm_certificate.alb) > 0 ? 1 : 0

  certificate_arn         = aws_acm_certificate.alb[0].arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}
