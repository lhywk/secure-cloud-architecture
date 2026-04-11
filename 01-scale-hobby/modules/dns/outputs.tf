# ACM
output "acm_certificate_arn" {
  description = "ACM 인증서 ARN (networking 모듈 ALB Listener에 전달). 도메인 없으면 빈 문자열."
  value       = length(aws_acm_certificate.alb) > 0 ? aws_acm_certificate.alb[0].arn : ""
}
