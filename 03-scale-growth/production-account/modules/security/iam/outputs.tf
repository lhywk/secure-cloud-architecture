output "task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "task_role_name" {
  value = aws_iam_role.ecs_task.name
}

output "instance_profile_arn" {
  value = aws_iam_instance_profile.ecs.arn
}

output "instance_role_arn" {
  value = aws_iam_role.ecs_instance.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}

output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}
