# 03 Scale — Growth

> [!IMPORTANT]
> 이 아키텍첸는 MAU 100만 명 규모의 서비스와 5개 페르소나(관리자·개발자·보안·감사·읽기전용)가 운영하는 환경을 기반으로 설계된 AWS 멀티어카운트 클라우드 아키텍첸입니다.

![Stage](https://img.shields.io/badge/Stage-03%20Growth-0A7E3B?style=flat-square)
![Scope](https://img.shields.io/badge/Scope-Multi%20Account-1F6FEB?style=flat-square)
![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?style=flat-square&logo=terraform&logoColor=white)
[![AWS](https://custom-icon-badges.demolab.com/badge/AWS-FF9900?style=flat-square&logo=aws&logoColor=white)](https://aws.amazon.com)

---

## 소개

<img src="../doc/images/03-scale-growth.png" align="center" alt="중규모 아키텍첸">

<br>

- AWS Organizations 기반 7개 계정, 3개 OU로 폭발 반경(Blast Radius)을 계정 경계로 격리
- ECS on EC2 + ElastiCache Redis + RDS Multi-AZ로 고가용성 애플리케이션 스택 구성
- SCP·IAM Identity Center·KMS CMK·GuardDuty·AWS Config로 엔터프라이즈 보안 레이어 적용
- 임직원 5개 페르소나, MAU 100만 명 규모를 가정

설계 의도와 위협 시나리오 등 자세한 내용은 저희의 [GitHub Pages 문서](https://unitelivedispersedie.github.io/secure-cloud-architecture-docs/)를 참고해주세요.

---

## 아키텍첸 흐름

```text
Internet
  → Route 53
  → CloudFront (WAF WebACL 연결, OAC)
      → S3 (정적 파일, KMS 암호화)
      → ALB (X-Origin-Secret 헤더 검증)
          → ECS on EC2 Auto Scaling (Private Subnet, IMDSv2)
              → RDS Multi-AZ MySQL 8.0 (DB Subnet, KMS 암호화)
              → ElastiCache Redis (DB Subnet, TLS + AUTH)

CloudTrail (Org Trail) → Log Archive S3 (Object Lock) + CloudWatch Logs → SNS → Email
GuardDuty → severity≥7 SNS 즉시 알림
AWS Config → 30개 관리형 룰 → EventBridge → SNS
Secrets Manager (secrets-cmk) → DB 자격증명 + API 키
GitHub Actions → OIDC → ECR Push + ECS Deploy (장기 크레덴셜 없음)
```

---

## 계정 구조

AWS Organizations 아래 7개 계정을 3개 OU로 구성합니다.  
각 Terraform 루트 디렉토리가 어느 계정을 담당하는지 확인하세요.

```text
Root
├── Management OU
│   └── management-account      ← Organizations, IAM Identity Center, SCPs
├── Production OU
│   ├── production-account      ← VPC, ECS, RDS, ElastiCache, CloudFront, WAF
│   ├── security-account        ← GuardDuty 위임 관리자, IAM Access Analyzer
│   └── log-archive-account     ← CloudTrail/Config 로그 S3, Object Lock
└── Dev OU
    ├── dev-account
    ├── staging-account
    └── sandbox-account
```

| Terraform 루트 | 담당 계정 | 주요 리소스 |
|---|---|---|
| `management-account/` | Management | Organizations, SCPs, IAM Identity Center, Permission Sets |
| `log-archive-account/` | Log Archive | S3 Object Lock, KMS s3-log-cmk |
| `security-account/` | Security | GuardDuty 위임 관리자, IAM Access Analyzer (ORGANIZATION) |
| `production-account/` | Production | 전체 애플리케이션 스택 |

> [!NOTE]
> Dev OU 계정은 별도 Terraform 루트로 관리하며 이 저장소의 범위에 포함되지 않습니다.

---

## 보안 설계 원칙

### SCP (Service Control Policy)
deny-list 전략으로 4개 레벨에 적용합니다.

| 정솵 | 적용 대상 | 주요 차단 항목 |
|---|---|---|
| `DenyRootUsage` | Root 전체 | 루트 계정 모든 API 호출 |
| `DenyLeaveOrganization` | Root 전체 | Organizations 탈퇴 |
| `DenyDisableSecurityServices` | Production OU | GuardDuty·CloudTrail·Config 비활성화 |
| `DenyNonApprovedRegions` | Production OU | 서울(ap-northeast-2) 외 리전 |

### IAM Identity Center (SSO)
5개 페르소나별 Permission Set으로 최소 권한을 구현합니다.

| 페르소나 | Permission Set | 접근 범위 |
|---|---|---|
| Admin | `AdministratorAccess` | Management 계정 한정 |
| Developer | 커스텀 (ECS·ECR·CloudWatch) | Production·Dev |
| Security | `SecurityAudit` | 전 계정 읽기 전용 |
| Auditor | `ReadOnlyAccess` | 전 계정 읽기 전용 |
| ReadOnly | `ViewOnlyAccess` | Production |

### KMS CMK 구성

| 키 | 계정 | 암호화 대상 |
|---|---|---|
| `rds-cmk` | Production | RDS, ElastiCache |
| `s3-cmk` | Production | 프론트엔드 S3, 앱 S3 |
| `secrets-cmk` | Production | Secrets Manager |
| `ebs-cmk` | Production | ECS EC2 EBS 볼륨 |
| `s3-log-cmk` | Log Archive | CloudTrail·Config 로그 S3 |

### 주요 보안 서비스

- **GuardDuty** — severity ≥ 7 즉시 SNS, CryptoCurrency·CredentialExfiltration 즉시 알림
- **AWS Config** — 30개 관리형 룰, 위반 시 EventBridge → SNS
- **IAM Access Analyzer** — ORGANIZATION 스코프, 외부 공개 리소스 탐지
- **WAFv2** — CloudFront 스코프, 5개 AWS 관리형 룰 그룹 + `/login` 레이트 리믳(20회/5분)
- **VPC Endpoints** — S3 Gateway, ECR, SSM, Secrets Manager 등 8개 (인터넷 미경유)

---

## 모듈 구성

### `production-account/` (메인 스택)

| 모듈 | 역할 |
|------|------|
| `kms` | 4개 CMK 생성 (rds·s3·secrets·ebs) |
| `dns` | Route 53 Zone 참조, ACM 인증서 (CloudFront용 us-east-1, ALB용 ap-northeast-2) |
| `security/secrets` | Secrets Manager 시크릿 쉘 생성 (DB 자격증명·API 키) |
| `security/iam` | ECS Task Role, Instance Profile, Execution Role, GitHub OIDC |
| `security/waf` | WAFv2 WebACL (CLOUDFRONT 스코프, us-east-1) |
| `security/config` | AWS Config 레코더·딘리버리·30개 관리형 룰·EventBridge |
| `network` | VPC 3계층, NACL, ALB, 8개 VPC Endpoint, 보안그룹, Flow Logs |
| `compute` | ECS Cluster, EC2 Launch Template (IMDSv2), ASG, ECR, ECS Task/Service |
| `database` | RDS Multi-AZ MySQL 8.0, ElastiCache Redis (TLS+AUTH), DB 자격증명 주입 |
| `cdn` | CloudFront (OAC), S3 프론트엔드 버킷, X-Origin-Secret 헤더 |
| `observability` | CloudTrail Org Trail, 10개 보안 메트릭 필터, 6개 서비스 알람, SNS |

### `management-account/`

| 모듈 | 역할 |
|------|------|
| `organizations` | OU·계정 구조, SCP 정솵 생성 및 연결 |
| `identity-center` | IAM Identity Center, 5개 Permission Set, 그룹 할당 |

### `log-archive-account/`

| 모듈 | 역할 |
|------|------|
| `storage` | CloudTrail·Config 로그 S3 (Object Lock COMPLIANCE 365일), s3-log-cmk |

### `security-account/`

| 모듈 | 역할 |
|------|------|
| `guardduty` | GuardDuty 위임 관리자, 조직 전체 자동 활성화 |
| `analyzer` | IAM Access Analyzer (ORGANIZATION 스코프) |

---

## Requirements

- Terraform >= 1.5.0
- AWS CLI >= 2.0 (configured)
- Route 53에서 사용할 도메인 소유권

---

## 사전 조건

`terraform apply` 전에 아래 항목을 **반드시** 수동으로 완료해야 합니다.

> [!WARNING]
> 이 단계를 건너뛰면 management-account Terraform이 Organizations·SSO 리소스를 찾지 못해 실패합니다.

1. **AWS Organizations 활성화**
   ```bash
   aws organizations create-organization --feature-set ALL
   ```

2. **IAM Identity Center 활성화**
   - AWS 콘솔 → IAM Identity Center → Enable

3. **Route 53 Hosted Zone 생성**
   - AWS 콘솔 → Route 53 → Hosted zones → Create hosted zone
   - 생성 후 NS 레코드를 도메인 등록 업체에 등록

4. **Log Archive 계정 S3 버킷 수동 생성** (닭-달걸 문제 회피)
   - CloudTrail이 버킷에 로그를 쓰려면 버킷이 먼저 존재해야 하고
   - 버킷 정첵에 CloudTrail ARN이 필요하므로 `log-archive-account`를 먼저 apply

---

## 적용 순서

멀티어카운트 구조에서는 Cross-account ARN 참조가 있으므로 **반드시 아래 순서대로** apply합니다.

```bash
# 1단계 — Log Archive (버킷 ARN을 이후 단계에서 참조)
terraform -chdir=03-scale-growth/log-archive-account init
terraform -chdir=03-scale-growth/log-archive-account apply

# 2단계 — Management (Organizations·SCP·SSO)
terraform -chdir=03-scale-growth/management-account init
terraform -chdir=03-scale-growth/management-account apply

# 3단계 — Security (GuardDuty·Access Analyzer)
terraform -chdir=03-scale-growth/security-account init
terraform -chdir=03-scale-growth/security-account apply

# 4단계 — Production (전체 애플리케이션 스택)
terraform -chdir=03-scale-growth/production-account init
terraform -chdir=03-scale-growth/production-account plan -var-file=terraform.tfvars -out tfplan
terraform -chdir=03-scale-growth/production-account apply tfplan
```

---

## tfvars 작성 가이드

`production-account/terraform.tfvars`를 새로 만들고 아래 항목을 채워주세요.  
(다른 계정 루트의 tfvars는 해당 디렉토리 내 `terraform.tfvars.example`을 참고하세요.)

### 공통 식별값

```hcl
project     = "myapp"
environment = "prod"
region      = "ap-northeast-2"
```

### Cross-account 참조

```hcl
# Security 계정 ID — KMS Key Policy의 cross-account 관리자 권한에 사용
security_account_id = "111122223333"

# Log Archive 계정에서 미리 생성한 S3 버킷 정보
log_archive_bucket_name  = "myapp-log-archive-444455556666"
log_archive_bucket_arn   = "arn:aws:s3:::myapp-log-archive-444455556666"
log_archive_kms_key_arn  = "arn:aws:kms:ap-northeast-2:444455556666:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### GitHub Actions OIDC

```hcl
github_org  = "my-github-org"
github_repo = "my-app-repo"
```

> 장기 크레덴셜(Access Key) 없이 OIDC 연동으로 ECR 푸시·ECS 배포를 수행합니다.

### 네트워크

```hcl
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["ap-northeast-2a", "ap-northeast-2c"]
public_subnet_cidrs  = ["10.0.1.0/24",  "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
db_subnet_cidrs      = ["10.0.21.0/24", "10.0.22.0/24"]
```

### 컴퓨팅 (ECS on EC2)

```hcl
instance_type        = "t3.medium"
asg_min_size         = 2
asg_max_size         = 8
asg_desired_capacity = 2

# ECR에 푸시된 이미지 URI (초기 배포 시 nginx:latest 등 플레이스홀더 가능)
container_image = "123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/myapp-prod:latest"
container_port  = 8080
```

### 데이터베이스

```hcl
db_name              = "appdb"
db_username          = "dbadmin"
db_instance_class    = "db.t3.medium"
db_allocated_storage = 100
```

> DB 비밀번호는 Secrets Manager에서 자동 생성됩니다. `tfvars`에 직접 입력하지 않습니다.

### ElastiCache Redis

```hcl
cache_node_type = "cache.t3.medium"
```

> Redis AUTH 토큰과 CloudFront 공유 시크릿은 `random_password`로 자동 생성 후 Secrets Manager에 저장됩니다.

### 도메인 및 S3

```hcl
domain_name             = "example.com"
cloudfront_price_class  = "PriceClass_200"

# 버킷 이름은 전역 고유값 — 뒤에 계정 ID를 붙이는 것을 권장합니다
s3_frontend_bucket_name = "myapp-prod-frontend-123456789012"
s3_app_bucket_name      = "myapp-prod-app-123456789012"
```

### 운영

```hcl
alarm_email                   = "ops@example.com"
cloudwatch_log_retention_days = 90
```

---

## 전체 tfvars 예시

```hcl
project     = "myapp"
environment = "prod"
region      = "ap-northeast-2"

security_account_id      = "111122223333"
log_archive_bucket_name  = "myapp-log-archive-444455556666"
log_archive_bucket_arn   = "arn:aws:s3:::myapp-log-archive-444455556666"
log_archive_kms_key_arn  = "arn:aws:kms:ap-northeast-2:444455556666:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

github_org  = "my-github-org"
github_repo = "my-app-repo"

vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["ap-northeast-2a", "ap-northeast-2c"]
public_subnet_cidrs  = ["10.0.1.0/24",  "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
db_subnet_cidrs      = ["10.0.21.0/24", "10.0.22.0/24"]

instance_type        = "t3.medium"
asg_min_size         = 2
asg_max_size         = 8
asg_desired_capacity = 2
container_image      = "123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/myapp-prod:latest"
container_port       = 8080

db_name              = "appdb"
db_username          = "dbadmin"
db_instance_class    = "db.t3.medium"
db_allocated_storage = 100

cache_node_type = "cache.t3.medium"

domain_name             = "example.com"
cloudfront_price_class  = "PriceClass_200"
s3_frontend_bucket_name = "myapp-prod-frontend-123456789012"
s3_app_bucket_name      = "myapp-prod-app-123456789012"

alarm_email                   = "ops@example.com"
cloudwatch_log_retention_days = 90
```

---

## 배포 후 체크리스트

- [ ] SNS 구독 메일 승인 확인 (GuardDuty 알림 + Ops 알람 2개 토픽)
- [ ] ACM 인증서 검증 완료 및 Route 53 레코드 반영 확인
- [ ] CloudFront 경유 트래픽 정상 응답 확인
- [ ] ALB DNS 직접 접근 시 `403` 반환 확인 (X-Origin-Secret 헤더 없음 → 차단)
- [ ] CloudTrail 로그가 Log Archive S3에 기록되는지 확인
- [ ] GuardDuty 활성화 및 조직 전체 자동 활성화 상태 확인
- [ ] AWS Config 레코더 활성화 및 규칙 평가 결과 확인
- [ ] RDS 퍼블릭 접근 불가·Multi-AZ·삭제 보호 상태 확인
- [ ] ElastiCache TLS 및 AUTH 토큰 적용 확인
- [ ] VPC Endpoint 8개 정상 생성 확인 (인터넷 게이트웨이 미경유)
- [ ] IAM Identity Center 페르소나별 로김 및 권한 테스트
- [ ] ECR에 컨테이너 이미지 푸시 후 ECS 서비스 정상 기동 확인
- [ ] ECS Task 루트리스(user 1000:1000) 실행 확인

---

## 제거

> [!WARNING]
> 멀티어카운트 구조이므로 적용 순서의 **역순**으로 destroy합니다.  
> RDS `deletion_protection = true`와 S3 Object Lock이 설정되어 있어 자동 삭제되지 않는 리소스가 있습니다.

```bash
# 역순 destroy
terraform -chdir=03-scale-growth/production-account destroy
terraform -chdir=03-scale-growth/security-account destroy
terraform -chdir=03-scale-growth/management-account destroy
terraform -chdir=03-scale-growth/log-archive-account destroy
```

> RDS 삭제 전 `deletion_protection`을 `false`로 변경 후 apply → destroy 순서로 진행하세요.  
> Log Archive S3는 Object Lock(COMPLIANCE 365일)으로 보호되어 있어 수동으로 버킷을 비운 후 삭제해야 합니다.
