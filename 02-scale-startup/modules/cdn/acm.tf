# ACM Certificate
# CloudFront must use certificates created specifically in the us-east-1 region.

# us-east-1 provider alias
# An alias provider must be declared in environments/prod(or dev)/main.tf
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# ACM Certificate Issuance (us-east-1)
# Wildcard certificate: covers both *.example.com and example.com simultaneously
resource "aws_acm_certificate" "main" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  # Ensure the new certificate is created before the existing one is deleted during replacement
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-acm"
  })
}

# Automatically create DNS validation records in Route 53
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# Wait for DNS validation to complete
resource "aws_acm_certificate_validation" "main" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}