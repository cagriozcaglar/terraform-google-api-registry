# Google Cloud API Gateway Module

This module is responsible for creating and managing APIs, API configurations, and gateways within Google Cloud API Gateway. It provides a flexible interface to define APIs from OpenAPI specifications, deploy them to publicly accessible endpoints, and manage different versions or configurations simultaneously.

## Usage

Below is a basic example of how to use this module to deploy an API Gateway.

```hcl
# main.tf

module "api_gateway" {
  source       = "./" # Replace with module path
  project_id   = "your-gcp-project-id"
  region       = "us-central1"
  api_id       = "my-example-api"
  display_name = "My Example API"

  api_configs = {
    "v1" = {
      display_name          = "Version 1"
      openapi_spec_path     = "spec.yaml"
      gateway_id            = "my-example-gateway"
      gateway_service_account = "my-backend-invoker-sa@your-gcp-project-id.iam.gserviceaccount.com"
    }
  }
}
```

```yaml
# spec.yaml
swagger: '2.0'
info:
  title: my-example-api
  description: An example API spec
  version: 1.0.0
schemes:
  - https
produces:
  - application/json
paths:
  /hello:
    get:
      summary: Greets a user
      operationId: hello
      x-google-backend:
        address: https://your-backend-service-url # e.g., a Cloud Run URL
      responses:
        '200':
          description: A successful response
          schema:
            type: string
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

The following sections describe the requirements for using this module.

### Software

The following software is required to use this module:

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Terraform Provider for Google Cloud](https://github.com/hashicorp/terraform-provider-google) >= 4.40.0
- [Terraform Provider for Google Cloud Beta](https://github.com/hashicorp/terraform-provider-google-beta) >= 4.40.0

### Service Account

A service account with the following roles is required to provision the resources of this module:

- API Gateway Admin: `roles/apigateway.admin`
- Service Account User: `roles/iam.serviceAccountUser`
- Service Usage Admin: `roles/serviceusage.serviceUsageAdmin` (to enable APIs)

The API Gateway service itself uses a Google-managed service account to invoke backends. This module outputs the service account's email as `api_gateway_service_agent`. You must grant this service account the necessary permissions to call your backend services. For example, to allow it to invoke a Cloud Run service, grant it the `roles/run.invoker` role.

### APIs

The following APIs must be enabled on the project:

- API Gateway API: `apigateway.googleapis.com`
- Service Management API: `servicemanagement.googleapis.com`
- Service Control API: `servicecontrol.googleapis.com`
- IAM API: `iam.googleapis.com`

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| api_configs | A map of API configurations and their associated gateways to create. The key of each object is a logical name for the configuration. Each configuration object supports the following attributes: `display_name` (string, required), `openapi_spec_path` (string, optional), `openapi_spec_contents` (string, optional), `gateway_id` (string, required), `gateway_display_name` (string, optional), `gateway_labels` (map(string), optional), `gateway_service_account` (string, optional). Exactly one of `openapi_spec_path` or `openapi_spec_contents` must be specified for each configuration. | <pre>map(object({<br>    display_name            = string<br>    openapi_spec_path       = optional(string)<br>    openapi_spec_contents   = optional(string)<br>    gateway_id              = string<br>    gateway_display_name    = optional(string)<br>    gateway_labels          = optional(map(string), {})<br>    gateway_service_account = optional(string)<br>  }))</pre> | `{}` | yes |
| api_id | A unique identifier for the top-level API. | `string` | `null` | yes |
| display_name | The display name of the API. Defaults to the value of `api_id`. | `string` | `null` | no |
| labels | A map of labels to apply to the API resource. | `map(string)` | `{}` | no |
| project_id | The project ID to host the API Gateway resources. | `string` | `null` | yes |
| region | The region for the gateways. | `string` | `null` | yes |

## Outputs

| Name | Description |
|------|-------------|
| api_configs | A map of the created API configs, keyed by the logical name provided in the input variable. Each value contains the config's full name and ID. |
| api_gateway_service_agent | The service agent email for the API Gateway service. This identity is used to invoke GCP backends (e.g., Cloud Functions, Cloud Run) and requires appropriate IAM permissions (e.g., roles/run.invoker). |
| api_id | The unique identifier of the created API. |
| api_name | The full resource name of the API in the format `projects/*/locations/global/apis/*`. |
| gateways | A map of the created gateways, keyed by the logical name provided in the input variable. Each value contains the gateway's ID and default hostname. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
