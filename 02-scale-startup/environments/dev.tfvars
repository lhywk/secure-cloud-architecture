
# 공통

project        = "myapp"
environment    = "dev"
region         = "ap-northeast-2"
aws_account_id = "130854680916"


# IAM

iam_users = ["dev-user1", "dev-user2"]


# 네트워크 (VPC)
# default 값이 있어 생략 가능하나 명시적으로 기재

vpc_cidr            = "10.0.0.0/16"
availability_zones  = ["ap-northeast-2a", "ap-northeast-2c"]
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]


# EC2 / Auto Scaling
# ami_id: Amazon Linux 2 (ap-northeast-2) — 실제 배포 전 최신 AMI로 교체

ami_id               = "ami-0c9c942bd7bf113a2"
instance_type        = "t3.small"
asg_min_size         = 1
asg_max_size         = 2
asg_desired_capacity = 1


# 데이터베이스 (RDS)
# db_username: sensitive — 실제 값은 AWS Secrets Manager 또는 CI/CD 환경변수로 주입 권장

db_name             = "appdb"
db_username         = "appuser"
db_instance_class   = "db.t3.micro"
db_allocated_storage = 20


# CloudFront + S3
# domain_name: Route53에 호스팅 존이 존재해야 함
# S3 버킷 이름은 전역 고유값이므로 실제 값으로 교체 필요

domain_name             = "example.com"
subdomain               = "www"
cloudfront_price_class  = "PriceClass_200"
s3_frontend_bucket_name = "myapp-dev-frontend"
s3_app_bucket_name      = "myapp-dev-app"
s3_log_bucket_name      = "myapp-dev-logs"


# KMS
# dev 환경에서는 삭제 대기 기간을 최소값(7일)으로 설정

kms_deletion_window = 7


# 모니터링

alarm_email                   = "dev-alert@example.com"
cloudwatch_log_retention_days = 14
