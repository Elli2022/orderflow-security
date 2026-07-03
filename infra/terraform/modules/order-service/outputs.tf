output "orders_table_name" {
  value = aws_dynamodb_table.orders.name
}

output "order_lambda_name" {
  value = aws_lambda_function.order.function_name
}

output "order_lambda_invoke_arn" {
  value = aws_lambda_function.order.invoke_arn
}

output "order_lambda_arn" {
  value = aws_lambda_function.order.arn
}
