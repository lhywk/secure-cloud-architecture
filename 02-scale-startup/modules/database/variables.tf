variable "environment" {
  description = "배포 환경 (dev / stg / prod)"
  type        = string
}

variable "public_subnet_ids" {
  description = "ASG가 배치될 퍼블릭 서브넷 ID 목록"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "RDS가 배치될 프라이빗 서브넷 ID 목록"
  type        = list(string)
}

variable "db_security_group_ids" {
  description = "RDS에 적용할 보안 그룹 ID 목록"
  type        = list(string)
}

variable "db_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
}

variable "kms_key_id" {
  description = "RDS 스토리지 암호화에 사용할 KMS 키 ARN (security 모듈 output)"
  type        = string
}

variable "db_secret_id" {
  description = "Secrets Manager에 저장된 DB 비밀번호 Secret ID (security 모듈 output)"
  type        = string
}

variable "tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
  default = {
    Project   = "my-project"
    ManagedBy = "terraform"
  }
}
