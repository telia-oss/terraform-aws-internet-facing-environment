# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------

### GLOBAL CONFIG ###
// Use json decode to load configuration file jsondecode(file("${path.module}/ife-configuration-example.json"))
variable "ife_configuration" {
  description = "Configuration file as JSON. Example file: ife-configuration-example.json"
  default     = ""
}

variable "region" {
  description = "AWS region where IFE will be applied and mandatory env variable for authorization lambda"
  type        = string
}

variable "environment" {
  description = "Environment name. Is used as a tag and API GW stage config"
  type        = string
}

variable "name" {
  description = "Custom name for IFE. Is used to tag resources"
  type        = string
  default     = ""
}

variable "project" {
  description = "Custom project for IFE. Is used to tag resources"
  type        = string
  default     = ""
}

### COGNITO CONFIG ###
variable "pool_name" {
  description = "Cognito pool name"
  type        = string
}

variable cognito_sub_domain {
  description = "Cognito sub domain where clients will request tokens. Its mandatory even if own domain is not used."
  type        = string
}

variable "cognito_use_own_domain" {
  description = "True if own domain should be used"
  type        = bool
  default     = false
}

variable "cognito_own_domain_certificate_arn" {
  description = "Own domain certificate ARN. This certificate must be managed by ACM in us-east-1"
  type        = string
  default     = ""
}

variable "cognito_own_domain" {
  description = "Own domain value"
  type        = string
  default     = ""
}

variable "param_store_client_prefix" {
  description = "Prefix used in parameter store where all client basic auth configurations will be stored"
  type        = string
  default     = "ife"
}

#API GATEWAY
variable "api_version" {
  description = "Version of API where deployment is triggered by changing this version"
  type        = number
  default     = 1
}

variable "root_path" {
  description = "Beginning path in URL following domain"
  type        = string
  default     = ""
}

variable "api_gw_log_retention" {
  description = "API gateway cloud watch logs retention in days"
  type        = number
  default     = 7
}

variable "nlb_arn" {
  description = "Private network load balancer arn which is needed for API GW VPC link setup"
  type        = string
}

variable "create_api_custom_domain" {
  description = "True if own domain should be used"
  type        = bool
  default     = false
}

variable "certificate_domain" {
  description = "Certificate domain where certificated in ACM is issued for. Use only if create_api_custom_domain = true"
  type        = string
  default     = ""
}

variable "api_sub_domain" {
  description = "API GW sub domain of certificate_domain. Use only if create_api_custom_domain = true"
  type        = string
  default     = ""
}

#LAMBDA
variable "lambda_log_retention" {
  description = "Lambda cloud watch log retention in days"
  type        = number
  default     = 30
}
