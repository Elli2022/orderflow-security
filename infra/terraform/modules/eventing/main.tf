variable "project_name" { type = string }
variable "environment" { type = string }
variable "kms_key_arn" { type = string }

resource "aws_cloudwatch_event_bus" "main" {
  name = "${var.project_name}-bus"

  tags = {
    Purpose = "order-domain-events"
  }
}

locals {
  queues = {
    payment      = "${var.project_name}-payment"
    inventory    = "${var.project_name}-inventory"
    notification = "${var.project_name}-notification"
  }
}

resource "aws_sqs_queue" "dlq" {
  for_each = local.queues

  name                      = "${each.value}-dlq"
  message_retention_seconds = 1209600 # 14 days
  kms_master_key_id         = var.kms_key_arn

  tags = {
    Purpose = "dead-letter-queue"
    Queue   = each.key
  }
}

resource "aws_sqs_queue" "main" {
  for_each = local.queues

  name                       = each.value
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600
  kms_master_key_id          = var.kms_key_arn

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = 3
  })

  tags = {
    Queue = each.key
  }
}

# Route OrderCreated events to payment and inventory queues
resource "aws_cloudwatch_event_rule" "order_created" {
  name           = "${var.project_name}-order-created"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["orderflow.order"]
    detail-type = ["OrderCreated"]
  })
}

resource "aws_cloudwatch_event_target" "payment" {
  rule           = aws_cloudwatch_event_rule.order_created.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = aws_sqs_queue.main["payment"].arn
  role_arn       = aws_iam_role.eventbridge_sqs.arn
}

resource "aws_cloudwatch_event_target" "inventory" {
  rule           = aws_cloudwatch_event_rule.order_created.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = aws_sqs_queue.main["inventory"].arn
  role_arn       = aws_iam_role.eventbridge_sqs.arn
}

resource "aws_sqs_queue_policy" "payment" {
  queue_url = aws_sqs_queue.main["payment"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.main["payment"].arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_cloudwatch_event_rule.order_created.arn
        }
      }
    }]
  })
}

resource "aws_sqs_queue_policy" "inventory" {
  queue_url = aws_sqs_queue.main["inventory"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.main["inventory"].arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_cloudwatch_event_rule.order_created.arn
        }
      }
    }]
  })
}

resource "aws_iam_role" "eventbridge_sqs" {
  name = "${var.project_name}-eventbridge-sqs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_sqs" {
  name = "sqs-send"
  role = aws_iam_role.eventbridge_sqs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["sqs:SendMessage"]
      Resource = [
        aws_sqs_queue.main["payment"].arn,
        aws_sqs_queue.main["inventory"].arn
      ]
    }]
  })
}
