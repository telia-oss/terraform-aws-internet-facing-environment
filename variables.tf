# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------

### GLOBAL CONFIG ###
// Use json decode to load configuration file jsondecode(file("${path.module}/ife-configuration-example.json"))
variable "ife_configuration" {
  description = "Configuration file as JSON. Example file: ife-configuration.json"
  default     = ""
}

variable "region" {
  description = "AWS region where IFE will be applied"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name. Is used as a tag and API GW stage config"
  type        = string
  default     = ""
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
  default     = ""
}

variable cognito_sub_domain {
  description = "Cognito sub domain where clients will requests tokens"
  type        = string
  default     = ""
}


#API GATEWAY
variable "api_version" {
  description = "Version of API where deployment is triggered by changing this version"
  type        = number
  default     = 1
}

variable "root_path" {
  description = "Beginning path in URL after domain"
  type        = string
  default     = ""
}

variable "api_gw_log_retetion" {
  description = "API gateway cloud watch logs retention in days"
  type        = number
  default     = 7
}

variable "nlb_arn" {
  description = "Private network load balancer arn which is needed for API GW VPC link setup"
  type        = string
  default     = ""
}

variable "create_api_custom_domain" {
  description = "True if own domain should be used. A"
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
