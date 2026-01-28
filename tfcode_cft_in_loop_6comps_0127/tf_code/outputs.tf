output "api_config_id" {
  description = "The full resource ID of the API config."
  value       = local.enabled ? google_api_gateway_api_config.config[0].id : null
}

output "api_id" {
  description = "The unique identifier for the created API."
  value       = local.enabled ? google_api_gateway_api.api[0].api_id : null
}

output "api_name" {
  description = "The full resource name of the API."
  value       = local.enabled ? google_api_gateway_api.api[0].name : null
}

output "default_hostname" {
  description = "The default hostname for the gateway."
  value       = local.enabled ? google_api_gateway_gateway.gateway[0].default_hostname : null
}

output "gateway_id" {
  description = "The full resource ID of the Gateway."
  value       = local.enabled ? google_api_gateway_gateway.gateway[0].id : null
}

output "gateway_name" {
  description = "The full resource name of the Gateway."
  value       = local.enabled ? google_api_gateway_gateway.gateway[0].name : null
}
