# ALB SG: CloudFront 관리형 접두사 목록에서만 HTTPS 수신
resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "ALB: CloudFront IP대역에서만 HTTPS/HTTP 수신"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTPS from CloudFront"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  ingress {
    description     = "HTTP from CloudFront (HTTPS redirect)"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    description = "ALB to ECS"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr_a, var.private_subnet_cidr_b]
  }

  tags = { Name = "${var.project}-${var.environment}-alb-sg", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# ECS SG: ALB에서만 8080 수신
resource "aws_security_group" "ecs" {
  name        = "${var.project}-${var.environment}-ecs-sg"
  description = "ECS Task: ALB에서만 8080 수신, DB/Cache 접근"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App port from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "HTTPS outbound (ECR/Secrets Manager via VPC Endpoint or NAT)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "MySQL to RDS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.db.id]
  }

  egress {
    description     = "Redis to ElastiCache"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.cache.id]
  }

  tags = { Name = "${var.project}-${var.environment}-ecs-sg", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

# DB SG: ECS에서만 MySQL 3306 수신
resource "aws_security_group" "db" {
  name        = "${var.project}-${var.environment}-db-sg"
  description = "RDS: ECS SG에서만 MySQL 3306 수신"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from ECS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = { Name = "${var.project}-${var.environment}-db-sg", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

# Cache SG: ECS에서만 Redis 6379 수신
resource "aws_security_group" "cache" {
  name        = "${var.project}-${var.environment}-cache-sg"
  description = "ElastiCache: ECS SG에서만 Redis 6379 수신"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis from ECS"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = { Name = "${var.project}-${var.environment}-cache-sg", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

# VPC Endpoint SG: HTTPS 수신
resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.project}-${var.environment}-vpce-sg"
  description = "VPC Endpoint: ECS/EC2에서 HTTPS 443 수신"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = { Name = "${var.project}-${var.environment}-vpce-sg", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}
