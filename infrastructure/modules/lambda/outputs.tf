
output "lambda_function_name" {
  description = "Name of the recovery trigger Lambda function"
  value       = aws_lambda_function.recovery_trigger.function_name
}

output "lambda_function_arn" {
  description = "ARN of the recovery trigger Lambda function"
  value       = aws_lambda_function.recovery_trigger.arn
}

output "lambda_invoke_arn" {
  description = "Invoke ARN of the recovery trigger Lambda function"
  value       = aws_lambda_function.recovery_trigger.invoke_arn
}

output "sns_subscription_arn" {
  description = "ARN of the SNS subscription to the Lambda function"
  value       = aws_sns_topic_subscription.lambda_target.arn
}
