variable "ife_configuration" {
  description = "IFE JSON configuration"
}

variable "root_path" {
  description = "Beginning path after API Gateway URL"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito user pool ARN for lambda authorizer"
  type        = string
}

variable "authorization_lambda_arn" {
  description = "API GW custom authorizer lambda ARN"
  type        = string
}

variable "authorization_lambda_invoke_arn" {
  description = "API GW custom authorizer lambda invoke ARN"
  type        = string
}

variable "nlb_arn" {
  description = "Network ELB arn for VPC link"
  type        = string
}

variable "stage_name" {
  description = "Stage name or environment for API deployment"
  type        = string
}

variable "api_version" {
  description = "When changed API GW deployes API"
  type        = number
}

variable "api_gw_log_retetion" {
  description = "API gateway cloud watch logs retention in days"
  type        = number
}

variable "create_custom_domain" {
  description = "Boolean if custom domain name should be created. Currently only AWS ACM supported"
  type        = bool
  default     = false
}

variable "certificate_domain" {
  description = "Domain to be used with API Gateway"
  type        = string
  default     = ""
}

variable "custom_sub_domain" {
  description = "Sub-domain to be used with API Gateway"
  type        = string
  default     = ""
}


variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}