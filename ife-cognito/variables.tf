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

variable "use_own_domain" {
  description = "Boolean if custom domain name should be created. Currently only AWS ACM supported This requires certificate in N. Virginia regiona"
  type        = bool
  default     = false
}

variable "own_domain" {
  description = "Domain to be used with Cognito"
  type        = string
  default     = ""
}
variable "zone_domain_name" {
  description = "Zone where A record will be created. Can be same as own domain"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "Arn of certificate issued for own domain"
  type        = string
  default     = ""
}

variable "param_store_client_prefix" {
  description = "Prefix used in parameter store where all client basic auth configurations will be stored"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}