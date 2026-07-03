variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alert_email" {
  type    = string
  default = ""
}

# --- KMS Keys (per data domain — SEC-003) ---

resource "aws_kms_key" "orders" {
  description             = "OrderFlow orders domain encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name   = "${var.project_name}-orders-kms"
    Domain = "orders"
    ADR    = "SEC-003"
  }
}

resource "aws_kms_alias" "orders" {
  name          = "alias/${var.project_name}/orders"
  target_key_id = aws_kms_key.orders.key_id
}

resource "aws_kms_key" "payments" {
  description             = "OrderFlow payments domain encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name   = "${var.project_name}-payments-kms"
    Domain = "payments"
    ADR    = "SEC-003"
  }
}

resource "aws_kms_alias" "payments" {
  name          = "alias/${var.project_name}/payments"
  target_key_id = aws_kms_key.payments.key_id
}

resource "aws_kms_key" "audit" {
  description             = "OrderFlow audit logs encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name   = "${var.project_name}-audit-kms"
    Domain = "audit"
    ADR    = "SEC-005"
  }
}

resource "aws_kms_alias" "audit" {
  name          = "alias/${var.project_name}/audit"
  target_key_id = aws_kms_key.audit.key_id
}

resource "aws_kms_key" "logs" {
  description             = "OrderFlow CloudWatch Logs encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name   = "${var.project_name}-logs-kms"
    Domain = "logs"
  }
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.project_name}/logs"
  target_key_id = aws_kms_key.logs.key_id
}

resource "aws_kms_key" "secrets" {
  description             = "OrderFlow Secrets Manager encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name   = "${var.project_name}-secrets-kms"
    Domain = "secrets"
    ADR    = "SEC-007"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}/secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# --- WAF (SEC-004) ---

resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project_name}-waf"
  description = "OrderFlow WAF - OWASP + rate limiting"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimitPerIP"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitPerIP"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    ADR = "SEC-004"
  }
}

# --- CloudTrail (SEC-005) ---

resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${var.project_name}-cloudtrail-${data.aws_caller_identity.current.account_id}"

  tags = {
    Purpose = "audit"
    ADR     = "SEC-005"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.audit.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid    = "DenyDeleteExceptBreakGlass"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:DeleteObject", "s3:DeleteObjectVersion"]
    resources = ["${aws_s3_bucket.cloudtrail.arn}/*"]
    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project_name}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.logs.arn
}

resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::DynamoDB::Table"
      values = ["arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-*"]
    }
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail]

  tags = {
    ADR = "SEC-005"
  }
}

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "${var.project_name}-cloudtrail-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "cloudtrail-logs"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
    }]
  })
}

# --- GuardDuty + Security Hub (SEC-006) ---

resource "aws_guardduty_detector" "main" {
  enable = true

  tags = {
    ADR = "SEC-006"
  }
}

resource "aws_securityhub_account" "main" {}

resource "aws_securityhub_standards_subscription" "cis" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/1.4.0"
}

# --- SNS for security alerts ---

resource "aws_sns_topic" "security_alerts" {
  name              = "${var.project_name}-security-alerts"
  kms_master_key_id = aws_kms_key.audit.id
}

resource "aws_sns_topic_subscription" "security_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
