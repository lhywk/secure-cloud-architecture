locals {
  name_prefix = "${var.project}-${var.environment}"
}

# IAM Users
resource "aws_iam_user" "this" {
    for_each = var.users
    name = each.key
}

# EC2 Role

resource "aws_iam_role" "ec2" {
    name = "${local.name_prefix}-ec2-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = { Service = "ec2.amazonaws.com" }
            Action = "sts:AssumeRole"
        }]
    })
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
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject",
                    "s3:ListBucket"
                ]
                Resource = [
                    var.s3_app_bucket_arn,
                    "${var.s3_app_bucket_arn}/*"
                ]
            },
            {
                Effect = "Allow"
                Action = [
                    "secretsmanager:GetSecretValue"
                ]
                Resource = [
                    var.secrets_arn
                ]
            },
            {
                Effect = "Allow"
                Action = [
                    "kms:Decrypt"
                ]
                Resource = [
                    var.kms_key_arn
                ]
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "ssm" {
    role = aws_iam_role.ec2.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app" {
    name = "${local.name_prefix}-app-instance-profile"
    role = aws_iam_role.ec2.name
}

# CloudTrail Role

resource "aws_iam_role" "cloudtrail" {
    name = "${local.name_prefix}-cloudtrail-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = { Service = "cloudtrail.amazonaws.com" }
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy" "cloudtrail" {
    name = "${local.name_prefix}-cloudtrail-policy"
    role = aws_iam_role.cloudtrail.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Action = [
                "s3:PutObject",
                "s3:GetBucketAcl"
            ]
            Resource = [
                var.s3_log_bucket_arn,
                "${var.s3_log_bucket_arn}/*"
            ]
        },{
            Effect = "Allow",
            Action = [ "kms:GenerateDataKey", "kms:Decrypt" ]
            Resource = [ var.kms_key_arn ]
        }]
    })
}

# admin role

resource "aws_iam_role" "admin" {
    name = "${local.name_prefix}-admin-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Effect = "Allow"
            Action = [ "sts:AssumeRole" ]
            Principal = {
                AWS = [ for u in aws_iam_user.this : u.arn ]
            }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "admin" {
    role = aws_iam_role.admin.name
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}