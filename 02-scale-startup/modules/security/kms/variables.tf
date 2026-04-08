variable "project" {
    description = "프로젝트 이름"
    type = string
}

variable "environment" {
    description = "배포 환경"
    type = string
}

variable "kms_deletion_window" {
    description = "KMS 키 삭제 대기 기간(일)"
    type = number
    default = 7
}

variable "enable_key_rotation" {
    description = "KMS 키 자동 교체 활성화 여부"
    type = bool
    default = true
}

variable "aws_account_id" {
    description = "AWS 계정 ID (키 정책에 사용)"
    type = string
}

variable "region" {
    description = "AWS 리전"
    type = string
}