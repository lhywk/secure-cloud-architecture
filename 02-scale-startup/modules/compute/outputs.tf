output "asg_name" {
  description = "Auto Scaling Group 이름"
  value       = aws_autoscaling_group.app_server.name
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.app_server.id
}

output "rds_endpoint" {
  description = "RDS 인스턴스 엔드포인트"
  value       = aws_db_instance.mysql.endpoint
}

output "rds_identifier" {
  description = "RDS 인스턴스 식별자"
  value       = aws_db_instance.mysql.identifier
}
