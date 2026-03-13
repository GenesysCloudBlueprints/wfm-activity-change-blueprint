resource "genesyscloud_flow" "wfm_activity_change_inbound_message_flow" {
  filepath = "${path.module}/WFMActivityChangeInboundMessageFlow.yaml"
  substitutions = {
    flow_name        = var.flow_name
    division_name    = var.division_name
    default_language = var.default_language
    bot_flow_name    = var.bot_flow_name
  }
}
