resource "genesyscloud_integration_action" "invoke_open_messaging" {
  name           = var.action_name
  category       = var.action_category
  integration_id = var.integration_id
  #   name           = "Invoke Open Messaging Inbound API via Chat Room"
  #   integration_id = genesyscloud_integration.Vivek_-_Genesys_Cloud_Data_Actions.id
  #   category       = "Vivek - Genesys Cloud Data Actions"
  #   secure         = false

  contract_input = jsonencode({
    "properties" : {
      "IntegrationID" : {
        "type" : "string"
      },
      "dateTime" : {
        "description" : "ISO-8601 (2025-04-14T21:15:00+0000)",
        "type" : "string"
      },
      "groupJid" : {
        "type" : "string"
      },
      "messageId" : {
        "description" : "Randomized Message ID from Open Messaging",
        "type" : "string"
      },
      "messageText" : {
        "type" : "string"
      },
      "userJid" : {
        "type" : "string"
      },
      "userid" : {
        "type" : "string"
      }
    },
    "type" : "object"
  })
  contract_output = jsonencode({
    "properties" : {
      "conversationId" : {
        "type" : "string"
      }
    },
    "type" : "object"
  })

  config_request {
    request_type         = "POST"
    request_url_template = "/api/v2/conversations/messages/$${input.IntegrationID}/inbound/open/message?prefetchConversationId=true"
    request_template     = "{\n  \"channel\": {\n    \"messageId\": \"$${input.messageId}\",\n    \"from\": {\n      \"id\": \"$${input.userJid}\",\n      \"idType\": \"opaque\"\n    },\n    \"metadata\": {\n      \"customAttributes\": {\n        \"groupJid\": \"$${input.groupJid}\",\n\"userJid\": \"$${input.userJid}\",\n\"userId\": \"$${input.userid}\"\n      }\n    },\n    \"time\": \"$${input.dateTime}\"\n  },\n  \"text\": \"$${input.messageText}\",\n  \"direction\": \"Inbound\"\n}"
  }
  config_response {
    success_template = "$${rawResult}"
  }
}
