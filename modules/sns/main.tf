# =============================================================================
# SNS 알림 설정
# =============================================================================

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-monitoring-alerts"
  
  tags = {
    Name = "${var.project_name}-alerts"
  }
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
