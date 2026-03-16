resource "genesyscloud_integration" "function_data_actions" {
  integration_type = "function-data-actions"
  intended_state   = "ENABLED"

  config {
    name = "${var.integration_name} ${var.environment_name}"
    credentials = {
      functionCredentials = genesyscloud_integration_credential.function_data_actions_credential.id
    }
  }
}

resource "genesyscloud_integration_credential" "function_data_actions_credential" {
  name                 = "${var.integration_name} Credential ${var.environment_name}"
  credential_type_name = "userDefined"
  fields = {
    clientId     = var.integration_creds_client_id
    clientSecret = var.integration_creds_client_secret
    region       = var.genesys_cloud_region
  }
}
