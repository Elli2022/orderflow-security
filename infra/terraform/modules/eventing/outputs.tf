output "event_bus_arn" {
  value = aws_cloudwatch_event_bus.main.arn
}

output "event_bus_name" {
  value = aws_cloudwatch_event_bus.main.name
}

output "dlq_queue_names" {
  value = [for k, q in aws_sqs_queue.dlq : q.name]
}

output "queue_arns" {
  value = { for k, q in aws_sqs_queue.main : k => q.arn }
}
