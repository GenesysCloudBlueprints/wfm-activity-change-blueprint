output "lambda_arn" {
  value = aws_lambda_function.wfm_activity_change_lambda.arn
}

output "lambda_url" {
  value = aws_lambda_function_url.wfm_activity_change_lambda_url.function_url
}
