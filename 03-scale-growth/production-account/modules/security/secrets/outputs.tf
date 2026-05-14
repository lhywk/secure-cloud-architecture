output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "redis_auth_secret_arn" {
  value = aws_secretsmanager_secret.redis_auth.arn
}

output "api_key_secret_arn" {
  value = aws_secretsmanager_secret.api_key.arn
}

output "cloudfront_origin_secret_arn" {
  value = aws_secretsmanager_secret.cloudfront_origin_secret.arn
}
