# main.tf 완성 작업 내역

## 1. 수정 파일 목록

| 파일 | 변경 유형 |
|------|-----------|
| `variables.tf` | 누락 변수 추가 |
| `main.tf` | 전체 재작성 |
| `modules/cdn/variables.tf` | 누락 변수 추가 |
| `modules/cdn/main.tf` | 깨진 참조 수정 |
| `modules/cdn/outputs.tf` | 누락 output 추가 |
| `modules/dns/acm.tf` | ALB용 인증서 추가 |
| `modules/dns/outputs.tf` | output 수정 및 추가 |
| `modules/dns/route53.tf` | 순환 의존성 제거 |

---

## 2. root variables.tf — 누락 변수 추가

| 변수 | 이유 |
|------|------|
| `aws_account_id` | `kms` 모듈이 KMS 키 정책에 계정 ID를 필요로 함 |
| `subdomain` | `dns`, `cdn` 모듈이 subdomain을 입력받음 (기본값: `"www"`) |

---

## 3. main.tf — 수정 사항

### 3-1. source 경로 오류 수정

| 모듈 | 기존 (오류) | 수정 |
|------|------------|------|
| `secrets` | `./module/security/secrets` | `./modules/security/secrets` |
| `compute` | `./module/compute` | `./modules/compute` |
| `database` | `./module/rds` | `./modules/database` |
| `dns` | `./module/dns` | `./modules/dns` |
| `observability` | `./module/obaservability` | `./modules/observability` |

### 3-2. 잘못된 output 참조 수정

| 모듈 | 기존 (오류) | 수정 |
|------|------------|------|
| `iam.rds_key_arn` | `module.security.kms.output.rds_key_arn` | `module.kms.rds_key_arn` |
| `secrets.kms_key_arn` | `modules.security.kms.secrets_key_arn` | `module.kms.secrets_key_arn` |
| `compute.iam_instance_profile_name` | `module.security.iam.ec2_instance_profile_name` | `module.iam.ec2_instance_profile_name` |
| `compute.kms_key_id` | `module.security.kms.rds_key_id` | `module.kms.rds_key_id` |
| `database.kms_key_id` | `module.security.iam.rds_key_id` | `module.kms.rds_key_id` |

### 3-3. 누락된 모듈 입력값 추가

| 모듈 | 추가된 입력값 |
|------|--------------|
| `network` | `private_subnet_cidr`, `alb_certificate_arn` |
| `kms` | `aws_account_id` |
| `iam` | `s3_app_bucket_arn`, `s3_log_bucket_arn`, `secrets_arn` |
| `compute` | `tags` |
| `database` | `db_secret_id`, `tags` |
| `observability` | `s3_log_bucket_name`, `cloudwatch_log_retention_days`, `asg_name` |
| `cdn` | `domain_name`, `subdomain`, `project`, `environment`, `s3_frontend_bucket_name`, `cloudfront_price_class`, `alb_dns_name`, `acm_certificate_arn`, `cloudfront_shared_secret` |

### 3-4. 불필요한 입력값 제거

| 모듈 | 제거된 입력값 | 이유 |
|------|--------------|------|
| `compute` | `project` | `compute` 모듈에 `project` 변수 없음 |
| `database` | `project` | `database` 모듈에 `project` 변수 없음 |

### 3-5. 모듈 이름 변경

| 기존 | 수정 | 이유 |
|------|------|------|
| `module "rds"` | `module "database"` | 실제 모듈 디렉토리 이름(`modules/database`)과 일치 |

### 3-6. standalone 리소스 추가

기존 모듈에서 관리하지 않는 리소스를 main.tf에 직접 추가:

**App S3 버킷** (`aws_s3_bucket.app`, `aws_s3_bucket_public_access_block.app`)
- `iam` 모듈이 `s3_app_bucket_arn`을 필요로 하지만, 어떤 모듈도 앱용 S3 버킷을 생성하지 않음

**CloudFront ↔ ALB 공유 시크릿** (`random_password.cloudfront_origin_secret`, `aws_secretsmanager_secret.cloudfront_origin`, `aws_secretsmanager_secret_version.cloudfront_origin`)
- `cdn` 모듈이 `cloudfront_shared_secret`을 필요로 함
- `network/alb.tf`가 `${project}/${environment}/origin-secret` 이름으로 Secrets Manager에서 직접 읽으므로, 동일한 이름으로 생성

**Route53 CloudFront A 레코드** (`data.aws_route53_zone.main`, `aws_route53_record.cloudfront`, `aws_route53_record.cloudfront_root`)
- 순환 의존성 해결을 위해 main.tf로 이동 (3-7 참조)

---

## 4. 순환 의존성 해결

### 문제 1: IAM ↔ Observability ↔ Compute

```
iam → observability (s3_log_bucket_arn 필요)
observability → compute (asg_name 필요)
compute → iam (ec2_instance_profile_name 필요)
```

**해결**: `iam` 모듈에 전달하는 `s3_log_bucket_arn`을 `module.observability.s3_log_bucket_arn` 대신 `"arn:aws:s3:::${var.s3_log_bucket_name}"`으로 직접 계산.
S3 ARN은 리전/계정 ID를 포함하지 않으므로 버킷 이름만으로 정확히 구성 가능.

### 문제 2: DNS ↔ CDN

```
dns → cdn (CloudFront domain_name, hosted_zone_id 필요 — Route53 A 레코드)
cdn → dns (acm_certificate_arn 필요 — CloudFront viewer certificate)
```

**해결**: dns/route53.tf의 CloudFront A 레코드를 root main.tf로 이동.
- `dns` 모듈: ACM 인증서 발급 + DNS 검증 레코드만 담당
- `cdn` 모듈: CloudFront 배포만 담당
- `main.tf`: `module.cdn.cloudfront_domain_name` / `cloudfront_hosted_zone_id`를 참조하여 Route53 A 레코드 생성

---

## 5. 모듈 파일 수정 사항

### 5-1. modules/cdn/variables.tf — 누락 변수 추가

```hcl
variable "acm_certificate_arn" {
  description = "ACM certificate ARN for CloudFront (us-east-1, output from the dns module)"
  type        = string
}
```

### 5-2. modules/cdn/main.tf — 깨진 참조 수정

`cdn/acm.tf` 삭제로 인해 `aws_acm_certificate_validation.main`이 모듈 내에 존재하지 않음.

```hcl
# 기존 (오류)
acm_certificate_arn = aws_acm_certificate_validation.main.certificate_arn
depends_on = [aws_acm_certificate_validation.main]

# 수정
acm_certificate_arn = var.acm_certificate_arn
# depends_on 제거 (의존성은 변수 참조로 자동 처리)
```

### 5-3. modules/cdn/outputs.tf — 누락 output 추가

```hcl
output "cloudfront_hosted_zone_id" {
  value = aws_cloudfront_distribution.main.hosted_zone_id
}
```
main.tf의 Route53 A 레코드 alias에서 사용.

### 5-4. modules/dns/acm.tf — ALB용 인증서 추가

CloudFront는 **us-east-1** 인증서를 요구하고, ALB는 **ap-northeast-2** 인증서를 요구함.
기존 dns/acm.tf는 us-east-1 인증서만 생성했으므로 ALB용 인증서를 추가:

```hcl
resource "aws_acm_certificate" "alb" { ... }           # ap-northeast-2 (provider alias 없음)
resource "aws_acm_certificate_validation" "alb" { ... } # CloudFront cert와 동일한 DNS 검증 레코드 재사용
```

### 5-5. modules/dns/outputs.tf — output 수정

| output | 기존 | 수정 |
|--------|------|------|
| `acm_certificate_arn` | `aws_acm_certificate.main.arn` (미검증) | `aws_acm_certificate_validation.main.certificate_arn` (검증 완료) |
| `alb_certificate_arn` | (없음) | `aws_acm_certificate_validation.alb.certificate_arn` 추가 |

### 5-6. modules/dns/route53.tf — CloudFront 레코드 제거

`aws_cloudfront_distribution.main` 참조(cdn 모듈 리소스)가 순환 의존성을 유발하므로 제거.
`data.aws_route53_zone.main` 데이터 소스는 `acm.tf`의 DNS 검증 레코드에서 사용하므로 유지.

---

## 6. 모듈 의존성 그래프 (최종)

```
dns
 ├── network (alb_certificate_arn)
 └── cdn (acm_certificate_arn)

kms
 ├── secrets (secrets_key_arn)
 ├── iam (rds_key_arn)
 ├── compute (rds_key_id)
 ├── database (rds_key_id)
 └── cloudfront_origin_secret (secrets_key_arn)

secrets
 ├── iam (secret_arn)
 └── database (secret_id)

app_s3_bucket
 └── iam (s3_app_bucket_arn)

network
 ├── compute (public/private_subnet_ids, app_sg_ids, target_group_arn)
 ├── database (public/private_subnet_ids, db_sg_ids)
 ├── observability (alb_arn)
 └── cdn (alb_dns_name)

iam
 └── compute (ec2_instance_profile_name)

compute
 └── observability (asg_name)

cdn
 └── main.tf Route53 records (cloudfront_domain_name, cloudfront_hosted_zone_id)
```
