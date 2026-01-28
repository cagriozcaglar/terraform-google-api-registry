variable "project_id" {
  description = "The project ID to host the API Gateway resources."
  type        = string
  default     = null
}

variable "region" {
  description = "The region for the gateways."
  type        = string
  default     = null
}

variable "api_id" {
  description = "A unique identifier for the top-level API."
  type        = string
  default     = null
}

variable "display_name" {
  description = "The display name of the API. Defaults to the value of `api_id`."
  type        = string
  default     = null
}

variable "labels" {
  description = "A map of labels to apply to the API resource."
  type        = map(string)
  default     = {}
}

variable "api_configs" {
  description = "A map of API configurations and their associated gateways to create. The key of each object is a logical name for the configuration. Each configuration object supports the following attributes: `display_name` (string, required), `openapi_spec_path` (string, optional), `openapi_spec_contents` (string, optional), `gateway_id` (string, required), `gateway_display_name` (string, optional), `gateway_labels` (map(string), optional), `gateway_service_account` (string, optional). Exactly one of `openapi_spec_path` or `openapi_spec_contents` must be specified for each configuration."
  type = map(object({
    display_name            = string
    openapi_spec_path       = optional(string)
    openapi_spec_contents   = optional(string)
    gateway_id              = string
    gateway_display_name    = optional(string)
    gateway_labels          = optional(map(string), {})
    gateway_service_account = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.api_configs :
      (v.openapi_spec_path != null || v.openapi_spec_contents != null) && !(v.openapi_spec_path != null && v.openapi_spec_contents != null)
    ])
    error_message = "For each api_config, exactly one of `openapi_spec_path` or `openapi_spec_contents` must be specified."
  }
}
