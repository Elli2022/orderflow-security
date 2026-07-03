output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.api.api_endpoint
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID for JWT authentication"
  value       = module.api.cognito_user_pool_id
}

output "cognito_client_id" {
  description = "Cognito App Client ID"
  value       = module.api.cognito_client_id
  sensitive   = true
}

output "cloudtrail_bucket" {
  description = "CloudTrail S3 bucket name"
  value       = module.security.cloudtrail_bucket_name
}

output "security_hub_arn" {
  description = "Security Hub ARN"
  value       = module.security.security_hub_arn
}

output "orders_table_name" {
  description = "DynamoDB orders table name"
  value       = module.order_service.orders_table_name
}

output "event_bus_name" {
  description = "EventBridge custom event bus name"
  value       = module.eventing.event_bus_name
}
