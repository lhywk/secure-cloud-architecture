resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = var.tags
}

resource "aws_elasticache_parameter_group" "redis7" {
  name   = "${var.project_name}-redis7"
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = var.tags
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project_name}-redis"
  description          = "Redis cluster for ${var.project_name}"

  node_type          = var.redis_node_type
  num_cache_clusters = 2
  port               = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [var.cache_security_group_id]

  parameter_group_name = aws_elasticache_parameter_group.redis7.name

  at_rest_encryption_enabled = true
  kms_key_id                 = var.secrets_cmk_arn
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token
  transit_encryption_mode    = "required"

  automatic_failover_enabled = true
  multi_az_enabled           = true

  engine_version = "7.0"

  snapshot_retention_limit = 7
  snapshot_window          = "03:00-05:00"
  maintenance_window       = "mon:05:00-mon:07:00"

  apply_immediately = false

  tags = merge(var.tags, { Name = "${var.project_name}-redis" })
}
