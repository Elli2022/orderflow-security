output "api_endpoint" {
  value = aws_apigatewayv2_api.main.api_endpoint
}

output "api_execution_arn" {
  value = aws_apigatewayv2_api.main.execution_arn
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.api.id
}
