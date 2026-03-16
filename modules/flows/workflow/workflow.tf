resource "genesyscloud_flow" "wfm_activity_change_workflow" {
  filepath = "${path.module}/WFMActivityChangeWorkflow.yaml"
  substitutions = {
    flow_name                              = var.flow_name
    division_name                          = var.division_name
    default_language                       = var.default_language
    integration_category                   = var.integration_category
    invoke_open_messaging_data_action_name = var.invoke_open_messaging_data_action_name
    open_messaging_integration_id          = var.open_messaging_integration_id
  }
}
