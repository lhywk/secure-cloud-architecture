# ──────────────────────────────────────────
# 알람 1: 루트 계정 콘솔 로그인 탐지
# 대응: 즉시 루트 계정 비밀번호 변경 + CloudTrail 이벤트 확인
# ──────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "root_login" {
  name        = "${var.project}-${var.environment}-root-login"
  description = "루트 계정 콘솔 로그인 탐지. 즉시 루트 계정 비밀번호 변경 + CloudTrail 이벤트 확인 필요."

  event_pattern = jsonencode({
    source      = ["aws.signin"]
    detail-type = ["AWS Console Sign In via CloudTrail"]
    detail = {
      userIdentity = {
        type = ["Root"]
      }
    }
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "root_login" {
  rule      = aws_cloudwatch_event_rule.root_login.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.alarm.arn
}

# ──────────────────────────────────────────
# 알람 2: IAM 유저 콘솔 로그인 탐지
# 대응: 내가 로그인한 게 아니면 크리덴셜 탈취 의심,
#        즉시 비밀번호 변경 및 세션 강제 종료
# ──────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "console_login" {
  name        = "${var.project}-${var.environment}-console-login"
  description = "IAM 유저 콘솔 로그인 탐지. 본인 로그인이 아니면 크리덴셜 탈취 의심, 즉시 비밀번호 변경 및 세션 강제 종료."

  event_pattern = jsonencode({
    source      = ["aws.signin"]
    detail-type = ["AWS Console Sign In via CloudTrail"]
    detail = {
      userIdentity = {
        type = ["IAMUser"]
      }
    }
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "console_login" {
  rule      = aws_cloudwatch_event_rule.console_login.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.alarm.arn
}
