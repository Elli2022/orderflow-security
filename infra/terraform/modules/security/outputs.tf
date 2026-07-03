output "orders_kms_key_arn" {
  value = aws_kms_key.orders.arn
}

output "payments_kms_key_arn" {
  value = aws_kms_key.payments.arn
}

output "audit_kms_key_arn" {
  value = aws_kms_key.audit.arn
}

output "logs_kms_key_arn" {
  value = aws_kms_key.logs.arn
}

output "secrets_kms_key_arn" {
  value = aws_kms_key.secrets.arn
}

output "waf_web_acl_arn" {
  value = aws_wafv2_web_acl.main.arn
}

output "cloudtrail_bucket_name" {
  value = aws_s3_bucket.cloudtrail.id
}

output "security_hub_arn" {
  value = aws_securityhub_account.main.arn
}

output "security_alerts_topic_arn" {
  value = aws_sns_topic.security_alerts.arn
}

output "guardduty_detector_id" {
  value = aws_guardduty_detector.main.id
}
