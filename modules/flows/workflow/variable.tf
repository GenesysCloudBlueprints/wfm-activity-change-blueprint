variable "flow_name" {
  type        = string
  description = "Name to assign to the workflow."
}

variable "division_name" {
  type        = string
  description = "Name of the Division to assign to the worklow."
}

variable "default_language" {
  type        = string
  description = "Default language for the workflow. Example: en-us"
}

variable "integration_category" {
  type        = string
  description = "Integration name to use for Data Actions in the workflow. Example: Genesys Cloud Data Actions"
}

variable "invoke_open_messaging_data_action_name" {
  type        = string
  description = "Name of the Data Action that invokes the Open Messaging Inbound API via Chat Room, to be used in the workflow."
}

variable "open_messaging_integration_id" {
  type        = string
  description = "Integration ID of the Open Messaging Integration that connects to your chat group, to be used in the workflow."
}
