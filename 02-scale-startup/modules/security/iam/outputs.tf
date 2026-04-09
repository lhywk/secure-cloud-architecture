output "ec2_instance_profile_name" {
    description = "EC2 모듈에 전달할 Instance Profile 이름"
    value = aws_iam_instance_profile.ec2.name
}

output "ec2_role_arn" {
    description = "EC2 IAM Role ARN"
    value = aws_iam_role.ec2.arn
}

output "cloudtrail_role_arn" {
    description = "CloudTrail 모듈에 전달할 Role ARN"
    value = aws_iam_role.cloudtrail.arn
}

output "admin_role_arn" {
    description = "Admin 권한을 가진 Role ARN"
    value = aws_iam_role.admin.arn
}

output "user_arns" {
    value = { for k, u in aws_iam_user.this : k => u.arn }
}