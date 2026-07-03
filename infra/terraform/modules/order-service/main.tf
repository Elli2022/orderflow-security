variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "private_subnets" { type = list(string) }
variable "orders_kms_arn" { type = string }
variable "logs_kms_arn" { type = string }
variable "event_bus_arn" { type = string }
variable "event_bus_name" { type = string }
variable "lambda_security_group_id" { type = string }

# --- DynamoDB Tables ---

resource "aws_dynamodb_table" "orders" {
  name         = "${var.project_name}-orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "orderId"

  attribute {
    name = "orderId"
    type = "S"
  }

  attribute {
    name = "customerId"
    type = "S"
  }

  global_secondary_index {
    name            = "customerId-index"
    hash_key        = "customerId"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.orders_kms_arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    DataClass = "confidential"
    ADR       = "SEC-003"
  }
}

resource "aws_dynamodb_table" "idempotency" {
  name         = "${var.project_name}-idempotency"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "idempotencyKey"

  attribute {
    name = "idempotencyKey"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.orders_kms_arn
  }

  tags = { Purpose = "api-idempotency" }
}

# --- Lambda ---

data "archive_file" "order_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../../../services/order"
  output_path = "${path.module}/order_lambda.zip"
}

resource "aws_iam_role" "order_lambda" {
  name = "${var.project_name}-order-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = { ADR = "SEC-001" }
}

resource "aws_iam_role_policy" "order_lambda" {
  name = "order-lambda-policy"
  role = aws_iam_role.order_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBOrders"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.orders.arn,
          "${aws_dynamodb_table.orders.arn}/index/*",
          aws_dynamodb_table.idempotency.arn
        ]
      },
      {
        Sid      = "EventBridgePublish"
        Effect   = "Allow"
        Action   = ["events:PutEvents"]
        Resource = var.event_bus_arn
        Condition = {
          StringEquals = {
            "events:source" = "orderflow.order"
          }
        }
      },
      {
        Sid      = "KMSOrders"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = var.orders_kms_arn
      },
      {
        Sid    = "Logs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/${var.project_name}-order:*"
      },
      {
        Sid    = "VPCAccess"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      },
      {
        Sid      = "XRay"
        Effect   = "Allow"
        Action   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "order_lambda" {
  name              = "/aws/lambda/${var.project_name}-order"
  retention_in_days = 30
  kms_key_id        = var.logs_kms_arn
}

resource "aws_lambda_function" "order" {
  function_name = "${var.project_name}-order"
  role          = aws_iam_role.order_lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  filename         = data.archive_file.order_lambda.output_path
  source_code_hash = data.archive_file.order_lambda.output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnets
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      ORDERS_TABLE      = aws_dynamodb_table.orders.name
      IDEMPOTENCY_TABLE = aws_dynamodb_table.idempotency.name
      EVENT_BUS_NAME    = var.event_bus_name
      LOG_LEVEL         = "INFO"
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [aws_cloudwatch_log_group.order_lambda]

  tags = {
    Service = "order"
  }
}
