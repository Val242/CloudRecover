
variable "lambda_execution_role_arn" {
  description = "ARN of the IAM execution role for Lambda"
  type        = string
}

variable "lambda_deployment_package" {
  description = "Path to the compiled Lambda deployment ZIP"
  type        = string
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name"
  type        = string
}

variable "github_workflow" {
  description = "GitHub Actions workflow filename or ID"
  type        = string
}

variable "github_ref" {
  description = "Git branch used for workflow dispatch"
  type        = string
  default     = "main"
}

variable "github_secret_arn" {
  description = "ARN of the GitHub token secret in Secrets Manager"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the primary health alarm SNS topic"
  type        = string
}

variable "lambda_s3_bucket" {
  description = "S3 bucket containing the Lambda deployment package"
  type        = string
}

variable "lambda_s3_key" {
  description = "S3 object key for the Lambda deployment package"
  type        = string
}