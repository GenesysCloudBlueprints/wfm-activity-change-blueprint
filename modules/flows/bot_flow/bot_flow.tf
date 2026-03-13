resource "genesyscloud_flow" "wfm_activity_change_bot_flow" {
  filepath = "${path.module}/WFMActivityChangeBotFlow.yaml"
  substitutions = {
    bot_name                               = var.bot_name
    division_name                          = var.division_name
    default_language                       = var.default_language
    data_action_integration_category       = var.data_action_integration_category
    get_business_unit_data_action_name     = var.get_business_unit_data_action_name
    get_agent_schedule_data_action_name    = var.get_agent_schedule_data_action_name
    wfm_status_mapping_data_table_name     = var.wfm_status_mapping_data_table_name
    function_integration_category          = var.function_integration_category
    adjust_agent_schedule_data_action_name = var.adjust_agent_schedule_data_action_name
  }
}
