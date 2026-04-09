output "rds_key_arn" {
    description = "RDS 암호화용 KMS 키 ARN"
    value = aws_kms_key.rds.arn
}

output "rds_key_id" {
    description = "RDS 암호화용 KMS 키 ID"
    value = aws_kms_key.rds.key_id
}

output "secrets_key_arn" {
    description = "Secrets Manager 암호화용 KMS 키 ARN"
    value = aws_kms_key.secrets.arn
}

output "secrets_key_id" {
    description = "Secrets Manager 암호화용 KMS 키 ID"
    value = aws_kms_key.secrets.key_id
}