variable "integration_name" {
  type        = string
  description = "The name of the Genesys Cloud integration."
}

variable "webhook_url" {
  type        = string
  description = "The URL for the outbound notification webhook."
}

variable "signature_secret_token" {
  type        = string
  description = "The signature secret token for validating webhook notifications."
}

variable "environment_name" {
  type        = string
  description = "The affix that will be added to resources to determine its environment."
  default     = "Dev"
}
