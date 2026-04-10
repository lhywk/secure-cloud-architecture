locals {
    name_prefix = "${var.project}-${var.environment}"
}

resource "aws_kms_key" "rds" {
    description = "${local.name_prefix} RDS encryption key"
    deletion_window_in_days = var.kms_deletion_window
    enable_key_rotation = var.enable_key_rotation

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid = "Enable IAM User Permissions"
                Effect = "Allow"
                Principal = {
                    AWS = "arn:aws:iam::${var.aws_account_id}:root"
                }
                Action = "kms:*"
                Resource = "*"
            },
            {
                Sid = "Allow RDS Service"
                Effect = "Allow"
                Principal = {
                    Service = "rds.amazonaws.com"
                }
                Action = [
                    "kms:GenerateDataKey",
                    "kms:Decrypt",
                    "kms:CreateGrant",
                    "kms:DescribeKey"
                ]
                Resource = "*"
            }
        ]
    })

    tags = {
        Name = "${local.name_prefix}-rds-kms-key"
        Project = var.project
        Environment = var.environment
        ManagedBy = "terraform"
    }
}

resource "aws_kms_alias" "rds" {
    name = "alias/${local.name_prefix}-rds"
    target_key_id = aws_kms_key.rds.key_id
}


# Secret Manager KMS Key

resource "aws_kms_key" "secrets" {
    description = "${local.name_prefix} Secrets Manager encryption key"
    deletion_window_in_days = var.kms_deletion_window
    enable_key_rotation = var.enable_key_rotation

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid = "Enable IAM User Permission"
                Effect = "Allow"
                Principal = {
                    AWS = "arn:aws:iam::${var.aws_account_id}:root"
                }
                Action = "kms:*"
                Resource = "*"
            },
            {
                Sid = "Allow Secrets Manager Service"
                Effect = "Allow"
                Principal = {
                    Service = "secretsmanager.amazonaws.com"
                }
                Action = [
                    "kms:GenerateDateKey",
                    "kms:Decrypt",
                    "kms:DescribeKey"
                ]
                Resource = "*"
            }
        ]
    })

    tags = {
        Name = "${local.name_prefix}-secrets-kms-key"
        Project = var.project
        Environment = var.environment
        ManagedBy = "terraform"
    }   
}

resource "aws_kms_alias" "secrets" {
        name = "alias/${local.name_prefix}-secrets"
        target_key_id = aws_kms_key.secrets.key_id
    }