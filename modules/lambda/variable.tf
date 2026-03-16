variable "environment_name" {
  type        = string
  description = "Name of the environment, e.g., dev, test, stable, staging, uat, prod etc."
}

variable "genesys_webhook_url" {
  type        = string
  description = "The webhook URL of the generated Generic webhook."
}

variable "zip_file_path" {
  type        = string
  description = "The file path of the zip file containing the Lambda function code."
}

variable "zip_file_hash" {
  type        = string
  description = "The base64-encoded SHA256 hash of the zip file, used to trigger updates when the file changes."
}
