variable "action_name" {
  type        = string
  description = "Name to associate with action"
}

variable "action_category" {
  type        = string
  description = "Action category to associate with action"
}

variable "integration_id" {
  type        = string
  description = "ID of the integration this action is associated with"
}

variable "filepath" {
  type        = string
  description = "The relative path to the source code zip file for the function integration."
}

variable "handler" {
  type        = string
  description = "The function within the source code that will be called when the action is invoked."
}

variable "runtime" {
  type        = string
  description = "The runtime environment for the function (e.g., nodejs22.x)."
}
