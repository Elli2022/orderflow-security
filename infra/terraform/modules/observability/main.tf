variable "project_name" { type = string }
variable "environment" { type = string }
variable "alert_email" { type = string }
variable "dlq_queue_names" { type = list(string) }
variable "lambda_names" { type = list(string) }

data "aws_sns_topic" "security" {
  name = "${var.project_name}-security-alerts"
}

# DLQ depth alarms
resource "aws_cloudwatch_metric_alarm" "dlq_depth" {
  for_each = toset(var.dlq_queue_names)

  alarm_name          = "${each.value}-messages-visible"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "DLQ has messages — investigate per INC-002"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = each.value
  }

  alarm_actions = [data.aws_sns_topic.security.arn]
}

# Lambda error rate alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = toset(var.lambda_names)

  alarm_name          = "${each.value}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Lambda error spike detected"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = each.value
  }

  alarm_actions = [data.aws_sns_topic.security.arn]
}
