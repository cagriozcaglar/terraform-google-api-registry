locals {
  # Decode the JSON string for openapi_documents to be used in the module.
  # An empty list is used as a fallback in case of decoding errors (though validation should prevent this).
  openapi_documents_list = try(jsondecode(var.openapi_documents), [])

  # Determines whether to create the API Gateway resources.
  # Creation is enabled only if the openapi_documents list is not empty.
  enabled = length(local.openapi_documents_list) > 0

  # Coalesce project_id and region with provider defaults if not provided.
  # These are only used when `local.enabled` is true.
  project_id = local.enabled ? coalesce(var.project_id, data.google_client_config.default[0].project) : null
  region     = local.enabled ? coalesce(var.region, data.google_client_config.default[0].region) : null

  # A list of Google Cloud services that are required for the API Gateway to function.
  required_services = [
    "apigateway.googleapis.com",
    "servicemanagement.googleapis.com",
    "servicecontrol.googleapis.com",
    "iam.googleapis.com"
  ]
}

# This data source is used to get the default project and region from the provider configuration.
# This allows the module to be more flexible, as project_id and region can be omitted
# if they are configured at the provider level.
data "google_client_config" "default" {
  # This data source is only queried if the module is enabled.
  count = local.enabled ? 1 : 0
}

# This resource enables the necessary Google Cloud services for the API Gateway.
# It is controlled by the 'enable_apis' variable.
resource "google_project_service" "apis" {
  # Enables one service for each element in the local.required_services list.
  count = local.enabled && var.enable_apis ? length(local.required_services) : 0
  # The project ID to enable the service in.
  project = local.project_id
  # The service to enable.
  service = local.required_services[count.index]

  # To prevent accidental disruption, services are not disabled when the gateway is destroyed.
  disable_on_destroy = false
}

# This resource retrieves the service identity for the API Gateway service.
# This service agent is a Google-managed service account that is created when the API is enabled.
# Using this resource ensures that we have a handle on the service account and can grant it
# IAM permissions without race conditions.
resource "google_project_service_identity" "apigw_sa" {
  # This resource is only created if the module is enabled.
  count = local.enabled ? 1 : 0
  # The provider to use for this resource. Beta is required for service identity.
  provider = google-beta
  # The project in which the service identity is retrieved.
  project  = local.project_id
  # The service for which to retrieve the identity.
  service  = "apigateway.googleapis.com"

  # Explicitly depend on API enablement to avoid race conditions where we try to get the
  # identity before the service and its corresponding service agent have been created.
  depends_on = [google_project_service.apis]
}

# This resource grants the API Gateway service agent the 'iam.serviceAccountUser' role
# on the specified gateway service account. This permission is necessary for the gateway
# to impersonate the service account when invoking backend services.
resource "google_service_account_iam_member" "apigw_sa_user" {
  # This IAM binding is only created if the module is enabled and a gateway service account is specified.
  count = local.enabled && var.gateway_service_account != null ? 1 : 0

  # The fully-qualified name of the service account to apply policy to, in the format projects/{project}/serviceAccounts/{email}.
  service_account_id = "projects/${local.project_id}/serviceAccounts/${var.gateway_service_account}"
  # The IAM role to grant. 'roles/iam.serviceAccountUser' allows the principal to impersonate the service account.
  role               = "roles/iam.serviceAccountUser"
  # The principal to grant the role to. This is the API Gateway service agent,
  # whose email is retrieved from the google_project_service_identity resource.
  member             = "serviceAccount:${google_project_service_identity.apigw_sa[0].email}"
}

# The google_api_gateway_api resource defines the API, which is a top-level container for configs and gateways.
resource "google_api_gateway_api" "api" {
  # A single instance of the API is created if the module is enabled.
  count = local.enabled ? 1 : 0

  # The provider to use for this resource. Beta is required for API Gateway.
  provider = google-beta
  # The ID of the project in which the resource belongs.
  project      = local.project_id
  # A unique identifier for the API.
  api_id       = var.api_id
  # A user-visible name for the API.
  display_name = var.api_display_name
  # Resource labels to represent user-provided metadata.
  labels       = var.labels

  # Explicitly depend on API enablement to avoid race conditions.
  depends_on = [google_project_service.apis]

  # The lifecycle block includes a precondition to ensure that an api_id is provided
  # when the module is enabled. This prevents apply-time failures for a required argument.
  lifecycle {
    precondition {
      condition     = var.api_id != null
      error_message = "The api_id variable must be set when openapi_documents is not empty."
    }
  }
}

# The google_api_gateway_api_config resource defines a specific version of an API's configuration,
# based on one or more OpenAPI specifications.
resource "google_api_gateway_api_config" "config" {
  # A single instance of the API config is created if the module is enabled.
  count = local.enabled ? 1 : 0

  # The provider to use for this resource. Beta is required for API Gateway.
  provider               = google-beta
  # The ID of the project in which the resource belongs.
  project                = local.project_id
  # The API to which this config is attached.
  api                    = google_api_gateway_api.api[0].api_id
  # The prefix for the API config ID. A unique ID will be generated by the provider.
  api_config_id_prefix   = var.api_config_id_prefix
  # A user-visible name for the API config.
  display_name           = var.api_config_display_name

  # Creates one or more openapi_documents blocks based on the input variable.
  dynamic "openapi_documents" {
    # Iterate over the list of documents decoded from the input variable.
    for_each = local.openapi_documents_list
    content {
      # The document block contains the specification for the API.
      document {
        # The path to the document, which can be used for display purposes.
        path     = openapi_documents.value.path
        # The base64-encoded contents of the OpenAPI document.
        contents = openapi_documents.value.contents
      }
    }
  }

  # Specifies the backend configuration for the gateway.
  # This block is only included if a gateway_service_account is provided.
  dynamic "gateway_config" {
    # Iterate only if a service account is provided.
    for_each = var.gateway_service_account != null ? [1] : []
    content {
      # Configuration for all backends.
      backend_config {
        # The service account used by the gateway to invoke backend services.
        google_service_account = var.gateway_service_account
      }
    }
  }

  # The lifecycle block ensures that a new API config is created before the old one is destroyed.
  # This is critical for preventing downtime when updating the API configuration.
  lifecycle {
    create_before_destroy = true
  }
}

# The google_api_gateway_gateway resource is the data plane that serves an API config and handles traffic.
resource "google_api_gateway_gateway" "gateway" {
  # A single instance of the gateway is created if the module is enabled.
  count = local.enabled ? 1 : 0

  # The provider to use for this resource. Beta is required for API Gateway.
  provider = google-beta

  # The ID of the project in which the resource belongs.
  project      = local.project_id
  # The region where the gateway will be created.
  region       = local.region
  # The API config to deploy to this gateway. This creates an implicit dependency on the config.
  api_config   = google_api_gateway_api_config.config[0].id
  # A unique identifier for the gateway.
  gateway_id   = var.gateway_id
  # A user-visible name for the gateway.
  display_name = var.gateway_display_name
  # Resource labels to represent user-provided metadata.
  labels       = var.labels

  # Explicitly depend on the IAM member resource to ensure permissions are set
  # before the gateway is created, preventing potential race conditions.
  depends_on = [google_service_account_iam_member.apigw_sa_user]

  # The lifecycle block includes preconditions to ensure that a gateway_id and region are provided
  # when the module is enabled. This prevents apply-time failures for required arguments.
  lifecycle {
    precondition {
      condition     = var.gateway_id != null
      error_message = "The gateway_id variable must be set when openapi_documents is not empty."
    }
    precondition {
      condition     = local.region != null
      error_message = "The region must be set via the 'region' variable or in the provider configuration when openapi_documents is not empty."
    }
  }
}
