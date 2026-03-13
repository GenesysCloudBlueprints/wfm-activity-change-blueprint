resource "aws_iam_role" "lambda_role" {
  name = "WFMActivityChangeLambdaRole-${var.environment_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_lambda_function" "wfm_activity_change_lambda" {
  filename         = var.zip_file_path
  function_name    = "wfm-activity-change-${var.environment_name}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  source_code_hash = var.zip_file_hash
  environment {
    variables = {
      DESTINATION_WEBHOOK_URL = var.genesys_webhook_url
    }
  }
}

resource "aws_lambda_function_url" "wfm_activity_change_lambda_url" {
  function_name      = aws_lambda_function.wfm_activity_change_lambda.function_name
  authorization_type = "NONE"
}
