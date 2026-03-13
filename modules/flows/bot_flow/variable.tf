variable "bot_name" {
  type        = string
  description = "Name to assign to the Bot Flow."
}

variable "division_name" {
  type        = string
  description = "Name of the Division to assign to the Bot Flow."
}

variable "default_language" {
  type        = string
  description = "Default language for the Bot Flow. Example: en-us"
}

variable "data_action_integration_category" {
  type        = string
  description = "Integration name to use for Data Action steps in the Bot Flow. Example: Genesys Cloud Data Actions"
}

variable "get_business_unit_data_action_name" {
  type        = string
  description = "Name of the Data Action that retrieves the agent's business unit. Example: Get Agent Business Unit"
}

variable "get_agent_schedule_data_action_name" {
  type        = string
  description = "Name of the Data Action that retrieves the agent's schedule. Example: Get Agent Schedule"
}

variable "wfm_status_mapping_data_table_name" {
  type        = string
  description = "Name of the Data Table that maps Genesys Cloud activity codes to WFM statuses. Example: WFM Status Mapping"
}

variable "function_integration_category" {
  type        = string
  description = "Integration name to use for Function Data Action steps in the Bot Flow. Example: Function Data Actions"
}

variable "adjust_agent_schedule_data_action_name" {
  type        = string
  description = "Name of the Function Data Action that adjusts the agent's schedule. Example: Adjust Agent Schedule"
}
