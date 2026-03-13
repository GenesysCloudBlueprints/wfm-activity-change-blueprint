resource "genesyscloud_conversations_messaging_integrations_open" "open_messaging_integration" {
  name                                                 = var.integration_name
  outbound_notification_webhook_url                    = var.webhook_url
  outbound_notification_webhook_signature_secret_token = var.signature_secret_token
}
