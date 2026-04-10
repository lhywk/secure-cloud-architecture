provider "aws" {
  region = var.region
}

# ──────────────────────────────────────────
# DNS / ACM
# 의존성 없음
# CloudFront(us-east-1)와 ALB(ap-northeast-2) 각각의 인증서를 발급
# ──────────────────────────────────────────
module "dns" {
  source = "./modules/dns"

  project     = var.project
  environment = var.environment

  domain_name = var.domain_name
  subdomain   = var.subdomain
}

# CloudFront → Route53 A 레코드
# dns/route53.tf의 cloudfront 레코드는 cdn 모듈과의 순환 의존성으로 인해 여기서 관리
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "cloudfront" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cdn.cloudfront_domain_name
    zone_id                = module.cdn.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cloudfront_root" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.cdn.cloudfront_domain_name
    zone_id                = module.cdn.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# ──────────────────────────────────────────
# Network
# 의존성: dns (alb_certificate_arn)
# ──────────────────────────────────────────
module "network" {
  source = "./modules/network"

  project     = var.project
  environment = var.environment

  vpc_cidr             = var.vpc_cidr
  availability_zone_a  = var.availability_zones[0]
  availability_zone_b  = var.availability_zones[1]
  public_subnet_cidr_a = var.public_subnet_cidrs[0]
  public_subnet_cidr_b = var.public_subnet_cidrs[1]
  private_subnet_cidr  = var.private_subnet_cidrs[0]

  alb_certificate_arn = module.dns.alb_certificate_arn
}

# ──────────────────────────────────────────
# KMS
# 의존성 없음
# RDS용, Secrets Manager용 키를 각각 생성
# ──────────────────────────────────────────
module "kms" {
  source = "./modules/security/kms"

  project     = var.project
  environment = var.environment

  kms_deletion_window = var.kms_deletion_window
  region              = var.region
  aws_account_id      = var.aws_account_id
}

# ──────────────────────────────────────────
# Secrets
# 의존성: kms
# DB 접속 정보를 Secrets Manager에 저장
# ──────────────────────────────────────────
module "secrets" {
  source = "./modules/security/secrets"

  project     = var.project
  environment = var.environment

  kms_key_arn = module.kms.secrets_key_arn
  db_username = var.db_username
  db_name     = var.db_name
}

# ──────────────────────────────────────────
# CloudFront ↔ ALB 공유 시크릿
# 의존성: kms
# CloudFront가 ALB로 요청 시 X-Origin-Secret 헤더에 삽입
# ALB는 network/alb.tf에서 이 시크릿을 Secrets Manager에서 직접 읽어 검증
# ──────────────────────────────────────────
resource "random_password" "cloudfront_origin_secret" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "cloudfront_origin" {
  name       = "${var.project}/${var.environment}/origin-secret"
  kms_key_id = module.kms.secrets_key_arn

  tags = {
    Name        = "${var.project}-${var.environment}-origin-secret"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "cloudfront_origin" {
  secret_id     = aws_secretsmanager_secret.cloudfront_origin.id
  secret_string = random_password.cloudfront_origin_secret.result
}

# ──────────────────────────────────────────
# App S3 버킷
# 의존성 없음
# EC2가 사용하는 애플리케이션용 S3 버킷 (별도 모듈 없이 직접 생성)
# ──────────────────────────────────────────
resource "aws_s3_bucket" "app" {
  bucket = var.s3_app_bucket_name

  tags = {
    Name        = var.s3_app_bucket_name
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ──────────────────────────────────────────
# IAM
# 의존성: kms, secrets, app S3 버킷
# 참고: s3_log_bucket_arn은 버킷 이름으로 직접 계산
#       (observability → compute → iam 순환 의존성 방지)
# ──────────────────────────────────────────
module "iam" {
  source = "./modules/security/iam"

  project     = var.project
  environment = var.environment

  users             = var.iam_users
  rds_key_arn       = module.kms.rds_key_arn
  s3_app_bucket_arn = aws_s3_bucket.app.arn
  s3_log_bucket_arn = "arn:aws:s3:::${var.s3_log_bucket_name}"
  secrets_arn       = module.secrets.secret_arn
}

# ──────────────────────────────────────────
# Compute
# 의존성: network, iam, kms
# ──────────────────────────────────────────
module "compute" {
  source = "./modules/compute"

  environment = var.environment

  public_subnet_ids      = module.network.public_subnet_ids
  private_subnet_ids     = module.network.private_subnet_ids
  app_security_group_ids = module.network.app_security_group_ids
  alb_target_group_arn   = module.network.target_group_arn

  iam_instance_profile_name = module.iam.ec2_instance_profile_name
  kms_key_id                = module.kms.rds_key_id

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ──────────────────────────────────────────
# Database
# 의존성: network, kms, secrets
# ──────────────────────────────────────────
module "database" {
  source = "./modules/database"

  environment = var.environment

  public_subnet_ids     = module.network.public_subnet_ids
  private_subnet_ids    = module.network.private_subnet_ids
  db_security_group_ids = module.network.db_security_group_ids

  kms_key_id   = module.kms.rds_key_id
  db_secret_id = module.secrets.secret_id

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ──────────────────────────────────────────
# Observability
# 의존성: network, compute
# CloudTrail, CloudWatch 알람, SNS 토픽 생성
# ──────────────────────────────────────────
module "observability" {
  source = "./modules/observability"

  project     = var.project
  environment = var.environment

  s3_log_bucket_name            = var.s3_log_bucket_name
  cloudwatch_log_retention_days = var.cloudwatch_log_retention_days
  alarm_email                   = var.alarm_email

  alb_arn  = module.network.alb_arn
  asg_name = module.compute.asg_name
}

# ──────────────────────────────────────────
# CDN
# 의존성: network, dns, cloudfront_origin_secret
# ──────────────────────────────────────────
module "cdn" {
  source = "./modules/cdn"

  project     = var.project
  environment = var.environment

  domain_name             = var.domain_name
  subdomain               = var.subdomain
  s3_frontend_bucket_name = var.s3_frontend_bucket_name
  cloudfront_price_class  = var.cloudfront_price_class

  alb_dns_name             = module.network.alb_dns_name
  acm_certificate_arn      = module.dns.acm_certificate_arn
  cloudfront_shared_secret = random_password.cloudfront_origin_secret.result

  depends_on = [aws_secretsmanager_secret_version.cloudfront_origin]
}
