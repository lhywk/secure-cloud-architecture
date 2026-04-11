terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.44"
    }
  }
}

provider "aws" {
  region = var.region
}

# ──────────────────────────────────────────
# S3 App Bucket
# ──────────────────────────────────────────

resource "aws_s3_bucket" "app" {
  bucket = var.s3_app_bucket_name

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ──────────────────────────────────────────
# Modules
# ──────────────────────────────────────────

module "security" {
  source = "./modules/security"

  project           = var.project
  environment       = var.environment
  iam_user_name     = var.iam_user_name
  s3_app_bucket_id  = aws_s3_bucket.app.id
  s3_app_bucket_arn = aws_s3_bucket.app.arn

  depends_on = [aws_s3_bucket_public_access_block.app]
}

module "observability" {
  source = "./modules/observability"

  project     = var.project
  environment = var.environment
  alarm_email = var.alarm_email
}
