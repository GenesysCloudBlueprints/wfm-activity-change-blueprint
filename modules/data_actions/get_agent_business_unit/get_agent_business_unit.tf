resource "genesyscloud_integration_action" "get_agent_business_unit" {
  name           = var.action_name
  category       = var.action_category
  integration_id = var.integration_id

  contract_input = jsonencode({
    "properties" : {
      "agentId" : {
        "type" : "string"
      }
    },
    "type" : "object"
  })
  contract_output = jsonencode({
    "properties" : {
      "businessUnit" : {
        "type" : "string"
      }
    },
    "type" : "object"
  })

  config_request {
    request_template     = "$${input.rawRequest}"
    request_type         = "GET"
    request_url_template = "/api/v2/workforcemanagement/agents/$${input.agentId}/managementunit"
  }
  config_response {
    success_template = "{\"businessUnit\": $${businessUnit}}"
    translation_map = {
      businessUnit = "$.businessUnit.id"
    }
  }
}
