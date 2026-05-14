resource "aws_sns_topic" "ops_alerts" {
  name              = "${var.project_name}-ops-alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = var.tags
}

resource "aws_sns_topic_subscription" "ops_email" {
  topic_arn = aws_sns_topic.ops_alerts.arn
  protocol  = "email"
  endpoint  = var.ops_email
}
