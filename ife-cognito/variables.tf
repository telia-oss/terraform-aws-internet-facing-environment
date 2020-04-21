variable "ife_configuration" {
  description = "IFE JSON configuration"
}

variable "cognito_pool_name" {
  description = "IFE cognito pool name"
  type        = string
}

variable "custom_sub_domain" {
  description = "Sub-domain to be used with Cognito. Domain prefix is mandatory"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}