# ──────────────────────────────────────────
# GuardDuty 디텍터 (Security Account 위임 관리자)
# ──────────────────────────────────────────
resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name      = "${var.project}-guardduty"
    Project   = var.project
    ManagedBy = "terraform"
  }
}

# 조직 수준에서 GuardDuty 자동 활성화 설정
resource "aws_guardduty_organization_configuration" "main" {
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.main.id

  datasources {
    s3_logs {
      auto_enable = true
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          auto_enable = true
        }
      }
    }
  }
}

# ──────────────────────────────────────────
# EventBridge 라우팅
# severity >= 7.0: 즉시 알림
# severity 4.0-6.9: 주간 리포트
# CryptoCurrency / CredentialExfiltration: 이외적으로 즉시 알림
# ──────────────────────────────────────────
resource "aws_cloudwatch_event_rule" "guardduty_high_critical" {
  name        = "${var.project}-guardduty-high-critical"
  description = "GuardDuty High/Critical 찾기 (severity >= 7.0) 즉시 알림"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", 7.0] }]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_high_critical_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_high_critical.name
  target_id = "SecuritySNS"
  arn       = var.sns_topic_arn

  input_transformer {
    input_paths = {
      severity   = "$.detail.severity"
      type       = "$.detail.type"
      account    = "$.detail.accountId"
      region     = "$.region"
      finding_id = "$.detail.id"
    }
    input_template = "\"GuardDuty [HIGH/CRITICAL] Finding\nSeverity: <severity>\nType: <type>\nAccount: <account>\nRegion: <region>\nFinding ID: <finding_id>\n\\n즉시 확인 필요\""
  }
}

resource "aws_cloudwatch_event_rule" "guardduty_critical_types" {
  name        = "${var.project}-guardduty-critical-types"
  description = "CryptoCurrency / InstanceCredentialExfiltration Finding 즉시 알림"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      type = [
        { prefix = "CryptoCurrency" },
        { prefix = "UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration" }
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_critical_types_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_critical_types.name
  target_id = "SecuritySNS"
  arn       = var.sns_topic_arn

  input_transformer {
    input_paths = {
      type    = "$.detail.type"
      account = "$.detail.accountId"
    }
    input_template = "\"[CRITICAL] GuardDuty 위협 탐지: <type> (Account: <account>). 즉시 대응 필요\""
  }
}

resource "aws_sns_topic_policy" "security_alerts" {
  arn = var.sns_topic_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowEventBridgePublish"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = var.sns_topic_arn
    }]
  })
}
