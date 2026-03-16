resource "genesyscloud_integration_action" "get_agent_schedule" {
  name           = var.action_name
  category       = var.action_category
  integration_id = var.integration_id
  #   category       = "Vivek - Genesys Cloud Data Actions"
  #   integration_id = genesyscloud_integration.Vivek_-_Genesys_Cloud_Data_Actions.id
  #   name           = "Get Agent Schedule"
  #   secure         = false

  contract_input = jsonencode({
    "additionalProperties" : true,
    "properties" : {
      "BusinessUnit" : {
        "description" : "ID of the business unit the agent belongs to. Can be obtained via API or UI",
        "type" : "string"
      },
      "EndDate" : {
        "description" : "in ISO 8601 format. eg. 2025-04-15T04:00:00.000Z",
        "type" : "string"
      },
      "StartDate" : {
        "description" : "in ISO 8601 format. eg. 2025-04-15T04:00:00.000Z",
        "type" : "string"
      },
      "UserID" : {
        "description" : "ID of the agent to get schedule for",
        "type" : "string"
      }
    },
    "type" : "object"
  })

  contract_output = jsonencode({
    "properties" : {
      "activityCodeId" : {
        "items" : {
          "type" : "string"
        },
        "type" : "array"
      },
      "activityLength" : {
        "items" : {
          "type" : "integer"
        },
        "type" : "array"
      },
      "startTime" : {
        "items" : {
          "type" : "string"
        },
        "type" : "array"
      }
    },
    "type" : "object"
  })

  config_request {
    request_template     = "{\n  \"userIds\": [\n    \"$${input.UserID}\"\n  ],\n  \"startDate\": \"$${input.StartDate}\",\n  \"endDate\": \"$${input.EndDate}\"\n}"
    request_type         = "POST"
    request_url_template = "/api/v2/workforcemanagement/businessunits/$${input.BusinessUnit}/agentschedules/search?forceDownloadService=false"
  }

  config_response {
    success_template = "{\"startTime\": $${startTime}, \"activityLength\": $${activityLength}, \"activityCodeId\": $${activityCodeId}}"
    translation_map = {
      activityCodeId = "$.result.agentSchedules[0].shifts[0].activities[*].activityCodeId"
      activityLength = "$.result.agentSchedules[0].shifts[0].activities[*].lengthMinutes"
      startTime      = "$.result.agentSchedules[0].shifts[0].activities[*].startDate"
    }
  }
}
