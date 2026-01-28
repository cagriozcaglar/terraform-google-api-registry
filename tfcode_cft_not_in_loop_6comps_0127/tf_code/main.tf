# The API Registry module is responsible for creating and managing APIs, API configurations,
# and gateways within Google Cloud API Gateway. It provides a flexible interface to define
# APIs from OpenAPI specifications, deploy them to publicly accessible endpoints, and manage
# different versions or configurations simultaneously.
# <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
# <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

locals {
  # Flag to determine if the core API resources should be created.
  create_api = var.project_id != null && var.api_id != null

  # Determine the OpenAPI spec content for each configuration, reading from a file if necessary.
  processed_api_configs = {
    for key, config in var.api_configs : key => {
      display_name            = config.display_name
      gateway_id              = config.gateway_id
      gateway_display_name    = coalesce(config.gateway_display_name, config.gateway_id)
      gateway_labels          = config.gateway_labels
      gateway_service_account = config.gateway_service_account
      spec_contents = base64encode(
        config.openapi_spec_contents != null ? config.openapi_spec_contents : file(config.openapi_spec_path)
      )
    }
  }
}

# The service identity for API Gateway, which is used to grant
# it permissions to invoke private backends like Cloud Run or Cloud Functions.
resource "google_project_service_identity" "apigateway" {
  # Use the beta provider for this resource.
  provider = google-beta
  # Create this resource only if project_id is provided.
  count = local.create_api ? 1 : 0
  # The project ID to retrieve the service identity for.
  project = var.project_id
  # The service for which to retrieve the identity.
  service = "apigateway.googleapis.com"

  # This lifecycle rule prevents the service agent from being destroyed, which
  # is critical for the functioning of the API Gateway.
  lifecycle {
    prevent_destroy = true
  }
}

# The top-level API resource in the API Registry. This groups multiple configurations.
resource "google_api_gateway_api" "api" {
  # Use the beta provider for this resource.
  provider = google-beta
  # Create this resource only if project_id and api_id are provided.
  count = local.create_api ? 1 : 0
  # The project ID where the API will be created.
  project = var.project_id
  # The unique identifier for this API.
  api_id = var.api_id
  # A user-friendly name for the API.
  display_name = coalesce(var.display_name, var.api_id)
  # Key-value string pairs to help organize and filter APIs.
  labels = var.labels
}

# An API Config, which uses an OpenAPI spec to define the API's behavior.
resource "google_api_gateway_api_config" "api_config" {
  # Use the beta provider for this resource.
  provider = google-beta
  # Create one config for each item in the var.api_configs map, if the API is being created.
  for_each = local.create_api ? local.processed_api_configs : {}

  # The project ID where the API Config will be created.
  project = google_api_gateway_api.api[0].project
  # The API that this configuration belongs to.
  api = google_api_gateway_api.api[0].api_id
  # A unique identifier for this API Config.
  api_config_id = "${var.api_id}-${each.key}-config"
  # A user-friendly name for the API Config.
  display_name = each.value.display_name

  # A list of OpenAPI documents that define the API.
  openapi_documents {
    document {
      # A logical path for the document.
      path = "spec.yaml"
      # The base64-encoded content of the OpenAPI spec.
      contents = each.value.spec_contents
    }
  }

  # Optional configuration for the gateway that deploys this config.
  dynamic "gateway_config" {
    # This block is always required, even if empty.
    for_each = [1]
    content {
      # Optional backend configuration.
      dynamic "backend_config" {
        # Only create this block if a service account is specified.
        for_each = each.value.gateway_service_account != null ? [each.value.gateway_service_account] : []
        content {
          # The service account used by the gateway to call backends.
          google_service_account = backend_config.value
        }
      }
    }
  }

  lifecycle {
    # Ensures that a new API config is created before the old one is destroyed,
    # preventing downtime when updating the gateway.
    create_before_destroy = true
  }
}

# The Gateway, which deploys an API Config to a public endpoint.
resource "google_api_gateway_gateway" "gateway" {
  # Use the beta provider for this resource.
  provider = google-beta
  # Create one gateway for each item in var.api_configs, if API and region are specified.
  for_each = local.create_api && var.region != null ? local.processed_api_configs : {}

  # The project ID where the Gateway will be created.
  project = google_api_gateway_api.api[0].project
  # The region where the Gateway will be deployed.
  region = var.region
  # The unique identifier for this Gateway.
  gateway_id = each.value.gateway_id
  # The API Config to deploy to this gateway.
  api_config = google_api_gateway_api_config.api_config[each.key].id
  # A user-friendly name for the Gateway.
  display_name = each.value.gateway_display_name
  # Key-value string pairs to help organize and filter Gateways.
  labels = each.value.gateway_labels
}
