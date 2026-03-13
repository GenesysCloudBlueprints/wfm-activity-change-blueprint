variable "integration_name" {
  type        = string
  description = "The name of the integration to be created."
}

variable "integration_creds_client_id" {
  type        = string
  description = "The Genesys Cloud oauth client ID."
}

variable "integration_creds_client_secret" {
  type        = string
  description = "The Genesys Cloud oauth client secret."
}

variable "genesys_cloud_region" {
  type        = string
  description = "The Genesys Cloud region the integration will be created in."
}

variable "environment_name" {
  type        = string
  description = "The affix that will be added to resources to determine its environment."
  default     = "Dev"
}
