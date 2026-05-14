locals {
  security_namespace = "${var.project_name}/SecurityMetrics"
}

resource "aws_cloudwatch_log_metric_filter" "root_login" {
  name           = "${var.project_name}-RootUserLogin"
  pattern        = "{ $.userIdentity.type = \"Root\" && $.eventType != \"AwsServiceEvent\" }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "RootUserLoginCount"
    namespace = local.security_namespace
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_login" {
  alarm_name          = "${var.project_name}-RootUserLogin"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RootUserLoginCount"
  namespace           = local.security_namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Root user login detected"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "mfa_less_login" {
  name           = "${var.project_name}-MFAlessConsoleLogin"
  pattern        = "{ $.eventName = \"ConsoleLogin\" && $.additionalEventData.MFAUsed != \"Yes\" && $.userIdentity.type != \"AssumedRole\" }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "MFAlessConsoleLoginCount"
    namespace = local.security_namespace
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "mfa_less_login" {
  alarm_name          = "${var.project_name}-MFAlessConsoleLogin"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "MFAlessConsoleLoginCount"
  namespace           = local.security_namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Console login without MFA detected"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "${var.project_name}-UnauthorizedAPICalls"
  pattern        = "{ ($.errorCode = \"*UnauthorizedAccess*\") || ($.errorCode = \"AccessDenied\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "UnauthorizedAPICallCount"
    namespace = local.security_namespace
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "${var.project_name}-UnauthorizedAPICalls"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnauthorizedAPICallCount"
  namespace           = local.security_namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Multiple unauthorized API calls detected"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "iam_changes" {
  name           = "${var.project_name}-IAMChanges"
  pattern        = "{ ($.eventSource = \"iam.amazonaws.com\") && (($.eventName = \"CreateUser\") || ($.eventName = \"CreateAccessKey\") || ($.eventName = \"AttachRolePolicy\") || ($.eventName = \"AttachUserPolicy\") || ($.eventName = \"PutRolePolicy\") || ($.eventName = \"PutUserPolicy\") || ($.eventName = \"CreatePolicy\") || ($.eventName = \"DeletePolicy\")) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "IAMChangesCount"
    namespace = local.security_namespace
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_changes" {
  alarm_name          = "${var.project_name}-IAMChanges"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "IAMChangesCount"
  namespace           = local.security_namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "IAM policy or user changes detected"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "sg_changes" {
  name           = "${var.project_name}-SecurityGroupChanges"
  pattern        = "{ ($.eventName = \"AuthorizeSecurityGroupIngress\") || ($.eventName = \"AuthorizeSecurityGroupEgress\") || ($.eventName = \"RevokeSecurityGroupIngress\") || ($.eventName = \"RevokeSecurityGroupEgress\") || ($.eventName = \"CreateSecurityGroup\") || ($.eventName = \"DeleteSecurityGroup\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "SGChangesCount"
    namespace = local.security_namespace
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "sg_changes" {
  alarm_name          = "${var.project_name}-SecurityGroupChanges"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "SGChangesCount"
  namespace           = local.security_namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Security group changes detected"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "cloudtrail_stopped" {
  name           = "${var.project_name}-CloudTrailStopped"
  pattern        = "{ ($.eventName = \"StopLogging\") || ($.eventName = \"DeleteTrail\") || ($.eventName = \"UpdateTrail\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "CloudTrailStoppedCount"
    namespace = local.security_namespace
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail_stopped" {
  alarm_name          = "${var.project_name}-CloudTrailStopped"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CloudTrailStoppedCount"
  namespace           = local.security_namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CloudTrail stopped or modified"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "guardduty_disabled" {
  name           = "${var.project_name}-GuardDutyDisabled"
  pattern        = "{ ($.eventSource = \"guardduty.amazonaws.com\") && (($.eventName = \"DeleteDetector\") || ($.eventName = \"DisassociateFromMasterAccount\") || ($.eventName = \"StopMonitoringMembers\")) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "GuardDutyDisabledCount"
    namespace = local.security_namespace
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "guardduty_disabled" {
  alarm_name          = "${var.project_name}-GuardDutyDisabled"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "GuardDutyDisabledCount"
  namespace           = local.security_namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "GuardDuty disabled or members removed"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "s3_policy_changes" {
  name           = "${var.project_name}-S3PolicyChanges"
  pattern        = "{ ($.eventSource = \"s3.amazonaws.com\") && (($.eventName = \"PutBucketAcl\") || ($.eventName = \"PutBucketPolicy\") || ($.eventName = \"DeleteBucketPolicy\")) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "S3PolicyChangesCount"
    namespace = local.security_namespace
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "s3_policy_changes" {
  alarm_name          = "${var.project_name}-S3PolicyChanges"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "S3PolicyChangesCount"
  namespace           = local.security_namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "S3 bucket policy or ACL changes detected"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "kms_key_deletion" {
  name           = "${var.project_name}-KMSKeyDeletion"
  pattern        = "{ ($.eventSource = \"kms.amazonaws.com\") && (($.eventName = \"DisableKey\") || ($.eventName = \"ScheduleKeyDeletion\")) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "KMSKeyDeletionCount"
    namespace = local.security_namespace
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "kms_key_deletion" {
  alarm_name          = "${var.project_name}-KMSKeyDeletion"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "KMSKeyDeletionCount"
  namespace           = local.security_namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "KMS key disabled or scheduled for deletion"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "organizations_leave" {
  name           = "${var.project_name}-OrganizationsLeave"
  pattern        = "{ ($.eventSource = \"organizations.amazonaws.com\") && ($.eventName = \"LeaveOrganization\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "OrganizationsLeaveCount"
    namespace = local.security_namespace
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "organizations_leave" {
  alarm_name          = "${var.project_name}-OrganizationsLeave"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "OrganizationsLeaveCount"
  namespace           = local.security_namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Attempt to leave AWS Organizations detected"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

# Service metric alarms

resource "aws_cloudwatch_metric_alarm" "alb_4xx" {
  alarm_name          = "${var.project_name}-ALB-4XXErrors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "ALB 4XX errors exceeded 100 in 5 minutes"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-ALB-5XXErrors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 20
  alarm_description   = "ALB 5XX errors exceeded 20 in 5 minutes"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "${var.project_name}-ECS-HighCPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS service CPU utilization exceeded 80%"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-RDS-HighCPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "RDS CPU utilization exceeded 90%"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "waf_blocked" {
  alarm_name          = "${var.project_name}-WAF-HighBlocked"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_description   = "WAF blocked more than 1000 requests in 5 minutes"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    WebACL = var.waf_web_acl_name
    Region = "us-east-1"
    Rule   = "ALL"
  }
}

resource "aws_cloudwatch_metric_alarm" "guardduty_findings" {
  alarm_name          = "${var.project_name}-GuardDuty-HighFindings"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "GuardDutyFindingsCount"
  namespace           = local.security_namespace
  period              = 3600
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "More than 10 GuardDuty findings in 1 hour (requires EventBridge custom metric publisher)"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}
