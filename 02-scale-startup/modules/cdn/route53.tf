# Route 53

# Reference existing hosted zone (Connects here once the domain is created)
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Link CloudFront to domain (A Record Alias)
# Reasons for using Alias:
# 1. CloudFront IPs change frequently -> Use Alias instead of CNAME
# 2. Can be applied to the root domain (example.com)
# 3. No Route 53 query costs
resource "aws_route53_record" "cloudfront" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

# Link root domain to CloudFront (Optional)
resource "aws_route53_record" "cloudfront_root" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}