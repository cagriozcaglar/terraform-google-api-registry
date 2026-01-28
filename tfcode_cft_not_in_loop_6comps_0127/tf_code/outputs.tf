output "api_name" {
  description = "The full resource name of the API in the format `projects/*/locations/global/apis/*`."
  value       = local.create_api ? google_api_gateway_api.api[0].name : null
}

output "api_id" {
  description = "The unique identifier of the created API."
  value       = local.create_api ? google_api_gateway_api.api[0].api_id : null
}

output "api_configs" {
  description = "A map of the created API configs, keyed by the logical name provided in the input variable. Each value contains the config's full name and ID."
  value = {
    for k, v in google_api_gateway_api_config.api_config : k => {
      name = v.name
      id   = v.id
    }
  }
}

output "gateways" {
  description = "A map of the created gateways, keyed by the logical name provided in the input variable. Each value contains the gateway's ID and default hostname."
  value = {
    for k, v in google_api_gateway_gateway.gateway : k => {
      id               = v.id
      gateway_id       = v.gateway_id
      default_hostname = v.default_hostname
    }
  }
}

output "api_gateway_service_agent" {
  description = "The service agent email for the API Gateway service. This identity is used to invoke GCP backends (e.g., Cloud Functions, Cloud Run) and requires appropriate IAM permissions (e.g., roles/run.invoker)."
  value       = local.create_api ? google_project_service_identity.apigateway[0].email : null
}
