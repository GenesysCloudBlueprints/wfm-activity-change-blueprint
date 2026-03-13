variable "client_id" {
  description = "OAuth Client ID for Genesys Cloud API"
  type        = string
}

variable "client_secret" {
  description = "OAuth Client Secret for Genesys Cloud API"
  type        = string
  sensitive   = true
}

variable "genesys_cloud_region" {
  description = "The region where the Genesys Cloud organization will be deployed. This will be used by the function data action that sets the region of the SDK client (refer to platformClient.PureCloudRegionHosts). eg. us_east_1, eu_west_1, ap_southeast_2, etc."
  type        = string
}

variable "group_name" {
  description = "The existing group name for the Activity Change Service. The blueprint requires this group to exist beforehand with the intended users added as members."
}

variable "default_language" {
  description = "The default language used for the flows. This is used when creating the flows."
  type        = string
  default     = "en-us"
}
variable "environment_name" {
  type        = string
  description = "The affix that will be added to resources to determine its environment."
  default     = "Dev"
}

variable "genesys_division_name" {
  description = "The name of the Genesys Cloud division where you want to deploy the resources."
  type        = string
  default     = "Home"
}

variable "genesys_webhook_url" {
  type        = string
  description = "The webhook URL of the generated Generic webhook. eg. https://apps.mypurecloud.com:443/webhooks/api/v1/webhook/some-uuid"
}

variable "generic_webhook_user_id" {
  type        = string
  description = "The user ID of the Genesys Cloud user that act as the owner of the Generic Webhook. Can be seen when accessing the user details from the Group Chat."
}
