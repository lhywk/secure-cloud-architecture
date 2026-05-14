resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_name}/rds/credentials"
  description             = "RDS database credentials"
  kms_key_id              = var.secrets_cmk_arn
  recovery_window_in_days = 30

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    port     = 3306
    dbname   = var.db_name
    engine   = "mysql"
  })
}

resource "aws_secretsmanager_secret" "redis_auth" {
  name                    = "${var.project_name}/redis/auth"
  description             = "Redis AUTH token"
  kms_key_id              = var.secrets_cmk_arn
  recovery_window_in_days = 30

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id = aws_secretsmanager_secret.redis_auth.id

  secret_string = jsonencode({
    auth_token = var.redis_auth_token
  })
}

resource "aws_secretsmanager_secret" "api_key" {
  name                    = "${var.project_name}/external/api-key"
  description             = "External API key"
  kms_key_id              = var.secrets_cmk_arn
  recovery_window_in_days = 30

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id = aws_secretsmanager_secret.api_key.id

  secret_string = jsonencode({
    api_key = var.api_key
  })
}

resource "aws_secretsmanager_secret" "cloudfront_origin_secret" {
  name                    = "${var.project_name}/cloudfront/origin-secret"
  description             = "CloudFront X-Origin-Secret header value"
  kms_key_id              = var.secrets_cmk_arn
  recovery_window_in_days = 30

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "cloudfront_origin_secret" {
  secret_id = aws_secretsmanager_secret.cloudfront_origin_secret.id

  secret_string = jsonencode({
    secret = var.cloudfront_origin_secret
  })
}
