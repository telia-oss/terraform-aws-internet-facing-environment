variable "lambda_log_retention" {
  description = "Lambda cloud watch log retention in days"
  type        = number
}

variable "env_region" {
  description = "Environment variable for lamda"
  type        = string
}

variable "env_user_pool_id" {
  description = "Environment variable for lamda"
  type        = string
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

variable "lambda_subnet_ids" {
  description = "VPC subnets for Lambda"
  type        = list(string)
  default     = []
}

variable "lambda_security_group_ids" {
  description = "SG IDs for Lambda, should at least allow all outbound"
  type        = list(string)
  default     = []
}
