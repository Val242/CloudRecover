resource "aws_lambda_function" "recovery_trigger" {
  function_name = "cloudrecover-recovery-trigger"
  description   = "Triggers the CloudRecover disaster recovery workflow"

  role = var.lambda_execution_role_arn

  runtime = "nodejs22.x"
  handler = "handler.handler"

  filename         = var.lambda_deployment_package
  source_code_hash = filebase64sha256(var.lambda_deployment_package)

  timeout     = 30
  memory_size = 256

  environment {
    variables = {
      GITHUB_OWNER      = var.github_owner
      GITHUB_REPOSITORY = var.github_repository
      GITHUB_WORKFLOW   = var.github_workflow
      GITHUB_REF        = var.github_ref
      GITHUB_SECRET_ARN = var.github_secret_arn
    }
  }
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.recovery_trigger.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
}

resource "aws_sns_topic_subscription" "lambda_target" {
  topic_arn = var.sns_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.recovery_trigger.arn

  depends_on = [
    aws_lambda_permission.allow_sns
  ]
}
