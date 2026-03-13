variable "flow_name" {
  type        = string
  description = "Name to assign to the flow."
}

variable "division_name" {
  type        = string
  description = "Name of the Division to assign to the flow."
}

variable "default_language" {
  type        = string
  description = "Default language for the flow. Example: en-us"
}

variable "bot_flow_name" {
  type        = string
  description = "Name to assign to the Bot Flow that will be called by the main flow."
}
