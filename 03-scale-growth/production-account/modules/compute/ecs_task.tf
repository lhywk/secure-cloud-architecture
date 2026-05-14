resource "aws_cloudwatch_log_group" "ecs_app" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 30
  kms_key_id        = var.secrets_cmk_arn

  tags = var.tags
}

resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${var.project_name}-ecs-execution-secrets"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = [
          var.db_secret_arn,
          var.redis_auth_secret_arn,
          var.secrets_cmk_arn
        ]
      }
    ]
  })
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  task_role_arn            = var.task_role_arn
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      cpu       = var.task_cpu
      memory    = var.task_memory
      essential = true
      user      = "1000:1000"

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.db_secret_arn}:password::"
        },
        {
          name      = "DB_USERNAME"
          valueFrom = "${var.db_secret_arn}:username::"
        },
        {
          name      = "REDIS_AUTH_TOKEN"
          valueFrom = "${var.redis_auth_secret_arn}:auth_token::"
        }
      ]

      environment = [
        {
          name  = "DB_HOST"
          value = var.db_endpoint
        },
        {
          name  = "REDIS_HOST"
          value = var.redis_endpoint
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "app"
        }
      }

      readonlyRootFilesystem = true

      linuxParameters = {
        capabilities = {
          drop = ["ALL"]
        }
      }
    }
  ])

  tags = var.tags
}
