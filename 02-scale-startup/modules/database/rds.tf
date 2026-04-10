resource "aws_db_subnet_group" "private_db" {
  name       = "${var.environment}-private-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-private-db-subnet-group"
      Environment = var.environment
    }
  )
}

resource "aws_db_instance" "mysql" {
  identifier        = "${var.environment}-rds-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "appdb"
  username = "admin"
  password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]

  db_subnet_group_name   = aws_db_subnet_group.private_db.name
  vpc_security_group_ids = var.db_security_group_ids

  # kms_key_id를 지정하지 않고 storage_encrypted만 활성화하면
  # RDS의 AWS managed key (aws/rds)로 스토리지가 암호화된다.
  storage_encrypted = true

  multi_az                = false
  publicly_accessible     = false
  backup_retention_period = var.environment == "prod" ? 7 : 0
  skip_final_snapshot     = var.environment != "prod"

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-rds-mysql"
      Environment = var.environment
    }
  )
}

# Secrets Manager에서 DB 비밀번호 참조 (security 모듈이 생성한 secret)
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.db_secret_id
}
