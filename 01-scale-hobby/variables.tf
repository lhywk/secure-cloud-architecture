variable "project" {
  description = "프로젝트 이름 (리소스 태그 및 네이밍에 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev / stg / prod)"
  type        = string
}

variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "iam_user_name" {
  description = "생성할 IAM 유저 이름"
  type        = string
}

variable "s3_app_bucket_name" {
  description = "App Server가 사용하는 S3 버킷 이름"
  type        = string
}

variable "alarm_email" {
  description = "CloudTrail 이벤트 알람을 수신할 이메일 주소"
  type        = string
}
