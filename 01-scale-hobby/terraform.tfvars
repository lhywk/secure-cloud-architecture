project     = "hobby"
environment = "dev"
region      = "ap-northeast-2"

# 네트워크
vpc_cidr            = "10.0.0.0/16"
availability_zone_a = "ap-northeast-2a"
availability_zone_b = "ap-northeast-2c"

# EC2 / ALB
app_port = 80

# S3
s3_app_bucket_name = "vibe-dev-app"

# DNS / ACM (도메인 없으면 빈 문자열 유지)
domain_name    = "beaverhobby.cloud"
hosted_zone_id = "Z02814322H2FWTX0H1J69"

iam_user_name = "hobby-admin"
alarm_email   = "lhywkd22@gmail.com"

github_repo = "lhywk/secure-cloud-architecture"
