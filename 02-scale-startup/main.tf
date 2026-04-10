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

  vpc_cidr              = var.vpc_cidr
  availability_zone_a   = var.availability_zones[0]
  availability_zone_b   = var.availability_zones[1]
  public_subnet_cidr_a  = var.public_subnet_cidrs[0]
  public_subnet_cidr_b  = var.public_subnet_cidrs[1]
  private_subnet_cidr   = var.private_subnet_cidrs[0]
  private_subnet_cidr_b = var.private_subnet_cidrs[1]

  alb_certificate_arn         = module.dns.alb_certificate_arn
  alb_access_logs_bucket_name = aws_s3_bucket.logs.id

  depends_on = [
    aws_secretsmanager_secret_version.cloudfront_origin,
    aws_s3_bucket_policy.logs,
  ]
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

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ──────────────────────────────────────────
# Audit / Log S3 버킷
# 의존성 없음
# ALB Access Log와 CloudTrail을 함께 저장하는 감사 로그 버킷
# ──────────────────────────────────────────
resource "aws_s3_bucket" "logs" {
  bucket              = var.s3_log_bucket_name
  object_lock_enabled = true

  tags = {
    Name        = var.s3_log_bucket_name
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = 90
    }
  }

  depends_on = [aws_s3_bucket_versioning.logs]
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

  depends_on = [aws_s3_bucket_public_access_block.logs]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/cloudtrail/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AllowCloudTrailACLCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logs.arn
      },
      {
        Sid    = "AllowALBWrite"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::600734575887:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/alb/*"
      },
      {
        Sid       = "DenyDelete"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:DeleteObject",
          "s3:DeleteBucket"
        ]
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
      },
      {
        Sid       = "DenyNonHttps"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "log-lifecycle"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# ──────────────────────────────────────────
# IAM
# 의존성: kms, secrets, app/log S3 버킷
# ──────────────────────────────────────────
module "iam" {
  source = "./modules/security/iam"

  project     = var.project
  environment = var.environment

  users             = var.iam_users
  secrets_key_arn   = module.kms.secrets_key_arn
  s3_app_bucket_arn = aws_s3_bucket.app.arn
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

  db_instance_class = var.db_instance_class
  kms_key_id        = module.kms.rds_key_arn
  db_secret_id      = module.secrets.secret_id

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  depends_on = [module.secrets]
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

  s3_log_bucket_name            = aws_s3_bucket.logs.id
  s3_log_bucket_arn             = aws_s3_bucket.logs.arn
  cloudwatch_log_retention_days = var.cloudwatch_log_retention_days
  alarm_email                   = var.alarm_email

  alb_arn  = module.network.alb_arn
  asg_name = module.compute.asg_name

  depends_on = [aws_s3_bucket_policy.logs]
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
