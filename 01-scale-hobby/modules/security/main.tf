locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ──────────────────────────────────────────
# IAM User
# ──────────────────────────────────────────

resource "aws_iam_user" "this" {
  name = var.iam_user_name

  tags = local.common_tags
}

resource "aws_iam_user_policy_attachment" "admin" {
  user       = aws_iam_user.this.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# MFA 미인증 시 전체 API Deny
resource "aws_iam_user_policy" "mfa_deny" {
  name = "${local.name_prefix}-mfa-deny"
  user = aws_iam_user.this.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Deny"
      Action   = "*"
      Resource = "*"
      Condition = {
        BoolIfExists = {
          "aws:MultiFactorAuthPresent" = "false"
        }
      }
    }]
  })
}

# ──────────────────────────────────────────
# EC2 Instance Role (최소 권한)
# ──────────────────────────────────────────

resource "aws_iam_role" "ec2" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "ec2" {
  name = "${local.name_prefix}-ec2-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_app_bucket_arn,
          "${var.s3_app_bucket_arn}/*"
        ]
      }
    ]
  })
}

# SSM Session Manager 접속
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_instance_profile" "app" {
  name = "${local.name_prefix}-app-instance-profile"
  role = aws_iam_role.ec2.name
}

# ──────────────────────────────────────────
# S3 App Bucket Policy
# EC2 Role만 허용 + HTTP 전체 Deny
# ──────────────────────────────────────────

resource "aws_s3_bucket_policy" "app" {
  bucket = var.s3_app_bucket_id

  depends_on = [aws_iam_role.ec2]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2Role"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2.arn
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_app_bucket_arn,
          "${var.s3_app_bucket_arn}/*"
        ]
      },
      {
        Sid       = "DenyNonHttps"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          var.s3_app_bucket_arn,
          "${var.s3_app_bucket_arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
