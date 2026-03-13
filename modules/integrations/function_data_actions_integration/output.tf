output "id" {
  value = genesyscloud_integration.function_data_actions.id
}

output "category" {
  value = genesyscloud_integration.function_data_actions.config.0.name
}
