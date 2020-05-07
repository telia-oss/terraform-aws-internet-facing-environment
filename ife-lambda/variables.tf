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

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}