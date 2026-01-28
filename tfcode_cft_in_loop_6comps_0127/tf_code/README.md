# Google Cloud API Gateway Module

This module handles the deployment of a managed Google Cloud API Gateway. It simplifies the process by creating the necessary API, API Config, and Gateway resources based on provided OpenAPI specifications.

This module will:
1.  Create a Google Cloud API.
2.  Create an API Config using one or more OpenAPI documents.
3.  Create a Gateway to serve the API Config.
4.  Optionally enable the required Google Cloud services.
5.  Optionally configure IAM permissions to allow the gateway to invoke backends using a specified service account.

Resource creation is conditional. If the `openapi_documents` variable is an empty list (`"[]"`), no resources will be created.

## Usage

Below is a basic example of how to use the module to deploy an API Gateway.

You will need an OpenAPI specification file (e.g., `openapi.yaml`) for your backend service.

```hcl
# main.tf

module "api_gateway" {
  source     = "./" # Or a reference to the module repository
  project_id = "your-gcp-project-id"
  region     = "us-central1"
  api_id     = "my-example-api"
  gateway_id = "my-example-gateway"

  openapi_documents = jsonencode([
    {
      path     = "openapi.yaml",
      contents = base64encode(file("${path.module}/openapi.yaml"))
    }
  ])

  # Optional: Use a specific service account for backends
  # gateway_service_account = "my-backend-sa@your-gcp-project-id.iam.gserviceaccount.com"

  labels = {
    environment = "dev"
    owner       = "team-alpha"
  }
}
```

```yaml
# openapi.yaml
# A minimal OpenAPI v2 spec for a backend (e.g., a Cloud Function or Cloud Run service)

swagger: "2.0"
info:
  title: "example-api"
  description: "An example API powered by Google Cloud API Gateway"
  version: "1.0.0"
schemes:
  - "https"
produces:
  - "application/json"
paths:
  /hello:
    get:
      summary: "Greets the user"
      operationId: "hello"
      x-google-backend:
        # Replace with the URL of your backend service
        address: "https://your-backend-service-url.a.run.app"
      responses:
        "200":
          description: "A successful response"
          schema:
            type: "string"

```

## Requirements

These sections describe requirements for using this module.

### Software

The following software is required:
- [Terraform](https://www.terraform.io/downloads.html) >= 1.3

### Service Account

A service account with the following roles is required to provision the resources of this module:

- API Gateway Admin: `roles/apigateway.admin`
- Service Usage Admin: `roles/serviceusage.serviceUsageAdmin` (only if `enable_apis` is `true`)
- Service Account User: `roles/iam.serviceAccountUser` (only if `gateway_service_account` is provided)

### APIs

A project with the following APIs enabled is required:

- API Gateway API: `apigateway.googleapis.com`
- Service Management API: `servicemanagement.googleapis.com`
- Service Control API: `servicecontrol.googleapis.com`
- Identity and Access Management (IAM) API: `iam.googleapis.com`

This module can enable these APIs automatically by setting the `enable_apis` variable to `true`.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](https://registry.terraform.io/providers/hashicorp/google) | >= 5.15.0 |
| <a name="provider_google-beta"></a> [google-beta](https://registry.terraform.io/providers/hashicorp/google-beta) | >= 5.15.0 |

## Resources

| Name | Type |
|------|------|
| [google_api_gateway_api.api](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/api_gateway_api) | resource |
| [google_api_gateway_api_config.config](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/api_gateway_api_config) | resource |
| [google_api_gateway_gateway.gateway](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/api_gateway_gateway) | resource |
| [google_project_service.apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service_identity.apigw_sa](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/project_service_identity) | resource |
| [google_service_account_iam_member.apigw_sa_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_client_config.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_config_display_name"></a> [api\_config\_display\_name](#input\_api\_config\_display\_name) | A user-visible name for the API config. | `string` | `"API Gateway Config"` | no |
| <a name="input_api_config_id_prefix"></a> [api\_config\_id\_prefix](#input\_api\_config\_id\_prefix) | The prefix for the API config ID. A unique ID will be generated. | `string` | `"api-config-"` | no |
| <a name="input_api_display_name"></a> [api\_display\_name](#input\_api\_display\_name) | A user-visible name for the API. | `string` | `"API Gateway API"` | no |
| <a name="input_api_id"></a> [api\_id](#input\_api\_id) | The identifier for the API. Must be unique within the project. Required if openapi\_documents is not an empty list. | `string` | `null` | yes |
| <a name="input_enable_apis"></a> [enable\_apis](#input\_enable\_apis) | When true, the necessary APIs for API Gateway will be enabled. Set to false if they are already enabled. | `bool` | `true` | no |
| <a name="input_gateway_display_name"></a> [gateway\_display\_name](#input\_gateway\_display\_name) | A user-visible name for the Gateway. | `string` | `"API Gateway"` | no |
| <a name="input_gateway_id"></a> [gateway\_id](#input\_gateway\_id) | The identifier for the Gateway. Must be unique within the project and region. Required if openapi\_documents is not an empty list. | `string` | `null` | yes |
| <a name="input_gateway_service_account"></a> [gateway\_service\_account](#input\_gateway\_service\_account) | The service account email to be used by the gateway to invoke backend services. The service account must be in the same project as the gateway. If it is not provided, the gateway will use the default App Engine service account. | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Resource labels to represent user-provided metadata. These are applied to the API and Gateway resources. | `map(string)` | `{}` | no |
| <a name="input_openapi_documents"></a> [openapi\_documents](#input\_openapi\_documents) | A JSON-encoded list of OpenAPI documents for the API config. Each document object in the list must have a 'path' and base64-encoded 'contents'. An empty list ('[]') will disable the creation of the gateway. | `string` | `"[]"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the Google Cloud project where the API Gateway will be created. If not provided, the provider project is used. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The Google Cloud region where the Gateway will be created. If not provided, the provider region is used. Required if openapi\_documents is not an empty list. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_config_id"></a> [api\_config\_id](#output\_api\_config\_id) | The full resource ID of the API config. |
| <a name="output_api_id"></a> [api\_id](#output\_api\_id) | The unique identifier for the created API. |
| <a name="output_api_name"></a> [api\_name](#output\_api\_name) | The full resource name of the API. |
| <a name="output_default_hostname"></a> [default\_hostname](#output\_default\_hostname) | The default hostname for the gateway. |
| <a name="output_gateway_id"></a> [gateway\_id](#output\_gateway\_id) | The full resource ID of the Gateway. |
| <a name="output_gateway_name"></a> [gateway\_name](#output\_gateway\_name) | The full resource name of the Gateway. |
