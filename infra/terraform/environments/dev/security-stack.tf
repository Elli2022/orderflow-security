module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  alert_email  = var.alert_email
}

module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.security.logs_kms_key_arn
}

module "eventing" {
  source = "../../modules/eventing"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.security.orders_kms_key_arn
}

module "order_service" {
  source = "../../modules/order-service"

  project_name             = var.project_name
  environment              = var.environment
  vpc_id                   = module.vpc.vpc_id
  private_subnets          = module.vpc.private_subnet_ids
  orders_kms_arn           = module.security.orders_kms_key_arn
  logs_kms_arn             = module.security.logs_kms_key_arn
  event_bus_arn            = module.eventing.event_bus_arn
  event_bus_name           = module.eventing.event_bus_name
  lambda_security_group_id = module.vpc.lambda_security_group_id
}

module "api" {
  source = "../../modules/api"

  project_name      = var.project_name
  environment       = var.environment
  order_lambda_arn  = module.order_service.order_lambda_invoke_arn
  order_lambda_name = module.order_service.order_lambda_name
  waf_web_acl_arn   = module.security.waf_web_acl_arn
}

# Allow API Gateway to invoke Order Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.order_service.order_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api.api_execution_arn}/*/*"
}

# Security alarms
module "observability" {
  source = "../../modules/observability"

  project_name    = var.project_name
  environment     = var.environment
  alert_email     = var.alert_email
  dlq_queue_names = module.eventing.dlq_queue_names
  lambda_names    = [module.order_service.order_lambda_name]
}
