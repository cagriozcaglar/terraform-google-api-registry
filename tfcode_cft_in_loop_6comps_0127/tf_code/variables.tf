variable "api_config_display_name" {
  description = "A user-visible name for the API config."
  type        = string
  default     = "API Gateway Config"
}

variable "api_config_id_prefix" {
  description = "The prefix for the API config ID. A unique ID will be generated."
  type        = string
  default     = "api-config-"
}

variable "api_display_name" {
  description = "A user-visible name for the API."
  type        = string
  default     = "API Gateway API"
}

variable "api_id" {
  description = "The identifier for the API. Must be unique within the project. Required if openapi_documents is not an empty list."
  type        = string
  default     = null
}

variable "enable_apis" {
  description = "When true, the necessary APIs for API Gateway will be enabled. Set to false if they are already enabled."
  type        = bool
  default     = true
}

variable "gateway_display_name" {
  description = "A user-visible name for the Gateway."
  type        = string
  default     = "API Gateway"
}

variable "gateway_id" {
  description = "The identifier for the Gateway. Must be unique within the project and region. Required if openapi_documents is not an empty list."
  type        = string
  default     = null
}

variable "gateway_service_account" {
  description = "The service account email to be used by the gateway to invoke backend services. The service account must be in the same project as the gateway. If it is not provided, the gateway will use the default App Engine service account."
  type        = string
  default     = null
}

variable "labels" {
  description = "Resource labels to represent user-provided metadata. These are applied to the API and Gateway resources."
  type        = map(string)
  default     = {}
}

variable "openapi_documents" {
  description = "A JSON-encoded list of OpenAPI documents for the API config. Each document object in the list must have a 'path' and base64-encoded 'contents'. An empty list ('[]') will disable the creation of the gateway."
  type        = string
  default     = "[]"

  validation {
    condition     = can(jsondecode(var.openapi_documents))
    error_message = "The openapi_documents variable must be a valid JSON string."
  }
}

variable "project_id" {
  description = "The ID of the Google Cloud project where the API Gateway will be created. If not provided, the provider project is used."
  type        = string
  default     = null
}

variable "region" {
  description = "The Google Cloud region where the Gateway will be created. If not provided, the provider region is used. Required if openapi_documents is not an empty list."
  type        = string
  default     = null
}
