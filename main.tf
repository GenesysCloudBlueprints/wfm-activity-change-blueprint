data "genesyscloud_auth_division" "target_division" {
  name = var.genesys_division_name
}

data "genesyscloud_group" "wfm_activity_change_group" {
  name = var.group_name
}

data "genesyscloud_organizations_me" "genesys_cloud_org" {}

# AWS Lambda Resources
resource "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.root}/src/lambda_code_source"
  output_path = "${path.root}/src/lambda_code.zip"
}

module "lambda" {
  source              = "./modules/lambda"
  environment_name    = var.environment_name
  genesys_webhook_url = var.genesys_webhook_url
  zip_file_path       = archive_file.lambda_zip.output_path
  zip_file_hash       = archive_file.lambda_zip.output_base64sha256
}

resource "random_password" "signature_secret_token" {
  length  = 32
  special = false
}

# Open Messaging Integration
module "open_messaging_integration" {
  depends_on             = [module.lambda]
  source                 = "./modules/integrations/open_messaging_integration"
  integration_name       = "WFM Activity Change Open Messaging Integration ${var.environment_name}"
  webhook_url            = module.lambda.lambda_url
  signature_secret_token = random_password.signature_secret_token.result
  environment_name       = var.environment_name
}

# Genesys Cloud Data Action integration
module "data_action_integration" {
  source                          = "git::https://github.com/GenesysCloudDevOps/public-api-data-actions-integration-module?ref=main"
  integration_name                = "WFM Activity Change Data Action Integration ${var.environment_name}"
  integration_creds_client_id     = var.client_id
  integration_creds_client_secret = var.client_secret
}

# Function Integration
module "function_integration" {
  source                          = "./modules/integrations/function_data_actions_integration"
  integration_name                = "WFM Activity Change Function Data Actions Integration"
  integration_creds_client_id     = var.client_id
  integration_creds_client_secret = var.client_secret
  environment_name                = var.environment_name
  genesys_cloud_region            = var.genesys_cloud_region
}


# Modules For Data Actions
module "adjust_agent_schedule_data_action" {
  depends_on      = [module.function_integration]
  source          = "./modules/data_actions/adjust_agent_schedule"
  action_name     = "Adjust Agent Schedule Data Action ${var.environment_name}"
  action_category = module.function_integration.category
  integration_id  = module.function_integration.id
  filepath        = "${path.root}/src/function_code.zip"
  handler         = "handler.updateSchedule"
  runtime         = "nodejs22.x"
}

module "get_agent_business_unit_data_action" {
  depends_on      = [module.data_action_integration]
  source          = "./modules/data_actions/get_agent_business_unit"
  action_name     = "Get Agent Business Unit Data Action ${var.environment_name}"
  action_category = module.data_action_integration.integration_name
  integration_id  = module.data_action_integration.integration_id
}

module "get_agent_schedule_data_action" {
  depends_on      = [module.data_action_integration]
  source          = "./modules/data_actions/get_agent_schedule"
  action_name     = "Get Agent Schedule Data Action ${var.environment_name}"
  action_category = module.data_action_integration.integration_name
  integration_id  = module.data_action_integration.integration_id
}

module "invoke_open_messaging_data_action" {
  depends_on      = [module.data_action_integration]
  source          = "./modules/data_actions/invoke_open_messaging"
  action_name     = "Invoke Open Messaging Data Action ${var.environment_name}"
  action_category = module.data_action_integration.integration_name
  integration_id  = module.data_action_integration.integration_id
}

# Data Table
module "data_table" {
  source      = "./modules/data_table"
  name        = "WFM Status Mapping ${var.environment_name}"
  division_id = data.genesyscloud_auth_division.target_division.id
}

# Module For Flows
module "bot_flow" {
  depends_on                             = [module.data_action_integration, module.get_agent_business_unit_data_action, module.get_agent_schedule_data_action, module.function_integration, module.adjust_agent_schedule_data_action]
  source                                 = "./modules/flows/bot_flow"
  bot_name                               = "WFM Activity Change Bot Flow ${var.environment_name}"
  division_name                          = var.genesys_division_name
  default_language                       = var.default_language
  data_action_integration_category       = module.data_action_integration.integration_name
  get_business_unit_data_action_name     = module.get_agent_business_unit_data_action.name
  get_agent_schedule_data_action_name    = module.get_agent_schedule_data_action.name
  wfm_status_mapping_data_table_name     = module.data_table.name
  function_integration_category          = module.function_integration.category
  adjust_agent_schedule_data_action_name = module.adjust_agent_schedule_data_action.name
}

module "inbound_message_flow" {
  depends_on       = [module.bot_flow]
  source           = "./modules/flows/inbound_message_flow"
  flow_name        = "WFM Activity Change Inbound Message Flow ${var.environment_name}"
  division_name    = var.genesys_division_name
  default_language = var.default_language
  bot_flow_name    = module.bot_flow.name
}

module "workflow" {
  depends_on                             = [module.data_action_integration, module.invoke_open_messaging_data_action, module.open_messaging_integration]
  source                                 = "./modules/flows/workflow"
  flow_name                              = "WFM Activity Change Workflow ${var.environment_name}"
  division_name                          = var.genesys_division_name
  default_language                       = var.default_language
  integration_category                   = module.data_action_integration.integration_name
  invoke_open_messaging_data_action_name = module.invoke_open_messaging_data_action.name
  open_messaging_integration_id          = module.open_messaging_integration.id
}

# Trigger
resource "genesyscloud_processautomation_trigger" "wfm_activity_change_inbound_message_trigger" {
  topic_name     = "v2.detail.events.collaboratechat.group.{id}.messages"
  enabled        = true
  match_criteria = "[{\"jsonPath\":\"to.entityId\",\"operator\":\"Equal\",\"value\":\"${data.genesyscloud_group.wfm_activity_change_group.id}\"},{\"jsonPath\":\"from.entityId\",\"operator\":\"NotEqual\",\"value\":\"${var.generic_webhook_user_id}\"}]"
  name           = "WFM Activity Change Message Trigger ${var.environment_name}"
  target {
    id   = module.workflow.id
    type = "Workflow"
    workflow_target_settings {
      data_format = "Json"
    }
  }
}

# NOTE: Additional Resources to be setup manually via UI
# Group
# Chat Webhook Integration (Then add the Group to the mapping and send a test message to the group to ensure the trigger is working and get the id of the Generic Webhook for Terraform)
# Then, deploy the Terraform Resources
# Message Routing (Route the generated Inbound Message Flow to the generated Open Messaging Integration)
