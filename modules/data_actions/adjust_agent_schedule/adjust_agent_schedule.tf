resource "genesyscloud_integration_action" "adjust_agent_schedule" {
  name           = var.action_name
  category       = var.action_category
  integration_id = var.integration_id

  contract_input = jsonencode({
    "properties" : {
      "activityCodeId" : {
        "type" : "string"
      },
      "agentId" : {
        "type" : "string"
      },
      "businessUnitId" : {
        "type" : "string"
      },
      "description" : {
        "type" : "string"
      },
      "lengthMinutes" : {
        "type" : "string"
      },
      "paid" : {
        "type" : "boolean"
      },
      "startDate" : {
        "type" : "string"
      },
      "windowEnd" : {
        "type" : "string"
      },
      "windowStart" : {
        "type" : "string"
      }
    },
    "type" : "object"
  })

  contract_output = jsonencode({
    "properties" : {},
    "type" : "object"
  })

  config_request {
    request_type     = "POST"
    request_template = "{\n  \"businessUnitId\": \"$!{input.businessUnitId}\",\n  \"agentId\": \"$!{input.agentId}\",\n  \"windowStart\": \"$!{input.windowStart}\",\n  \"windowEnd\": \"$!{input.windowEnd}\",\n  \"clientId\": \"$!{credentials.clientId}\",\n  \"clientSecret\": \"$!{credentials.clientSecret}\",\n  \"gcRegion\": \"$!{credentials.region}\",\n  \"shiftChange\": {\n    \"startDate\": \"$${input.startDate}\",\n    \"lengthMinutes\": $${input.lengthMinutes},\n    \"description\": \"$${input.description}\",\n    \"activityCodeId\": \"$${input.activityCodeId}\",\n    \"paid\": $${input.paid}\n  }\n}\n"
  }

  config_response {
    success_template = "$${rawResult}"
  }

  function_config {
    file_path       = var.filepath
    handler         = var.handler
    runtime         = var.runtime
    timeout_seconds = 15
  }
}
