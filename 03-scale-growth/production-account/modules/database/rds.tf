resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = merge(var.tags, { Name = "${var.project_name}-rds-subnet-group" })
}

resource "aws_db_parameter_group" "mysql8" {
  name   = "${var.project_name}-mysql8"
  family = "mysql8.0"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "log_output"
    value = "FILE"
  }

  tags = var.tags
}

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-rds"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.rds_instance_class

  allocated_storage     = 100
  max_allocated_storage = 500
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.rds_cmk_arn

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]
  parameter_group_name   = aws_db_parameter_group.mysql8.name

  multi_az               = true
  publicly_accessible    = false
  deletion_protection    = true
  skip_final_snapshot    = false
  final_snapshot_identifier = "${var.project_name}-rds-final-snapshot"

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = var.rds_cmk_arn
  performance_insights_retention_period = 7

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  tags = merge(var.tags, { Name = "${var.project_name}-rds" })
}
