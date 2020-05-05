# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------

locals {
  #GLOBAL
  ife_configuration = var.ife_configuration

  aws_region  = var.region
  environment = var.environment
  tags = {
    name        = var.name
    project     = var.project
    environment = local.environment
  }

  #COGNITO
  pool_name                          = var.pool_name
  cognito_sub_domain                 = var.cognito_sub_domain
  cognito_use_own_domain             = var.cognito_use_own_domain
  cognito_own_domain_certificate_arn = var.cognito_own_domain_certificate_arn
  cognito_own_domain                 = var.cognito_own_domain

  #API GATEWAY
  api_version = var.api_version
  root_path   = var.root_path
  nlb_arn     = var.nlb_arn

  api_gw_log_retention = var.api_gw_log_retetion

  create_api_custom_domain = var.create_api_custom_domain
  certificate_domain       = var.certificate_domain
  api_sub_domain           = var.api_sub_domain

  #LAMBDA
  lambda_log_retention = var.lambda_log_retention
}

module "ife_cognito" {
  source = "./ife-cognito"

  cognito_pool_name = local.pool_name
  ife_configuration = local.ife_configuration

  custom_sub_domain = local.cognito_sub_domain
  use_own_domain    = local.cognito_use_own_domain
  certificate_arn   = local.cognito_own_domain_certificate_arn
  own_domain        = local.cognito_own_domain
  zone_domain_name  = local.certificate_domain

  tags = local.tags
}

module "ife_authorization_lambda" {
  source = "./ife-lambda"

  env_region       = local.aws_region
  env_user_pool_id = module.ife_cognito.cognito_pool_id

  lambda_log_retention = local.lambda_log_retention
  tags                 = local.tags
}


module "ife_api_gateway" {
  source = "./ife-api-gateway"

  ife_configuration = local.ife_configuration

  root_path                       = local.root_path
  cognito_user_pool_arn           = module.ife_cognito.cognito_pool_arn
  authorization_lambda_arn        = module.ife_authorization_lambda.authorization_lambda_arn
  authorization_lambda_invoke_arn = module.ife_authorization_lambda.authorization_lambda_invoke_arn

  nlb_arn     = local.nlb_arn
  stage_name  = local.environment
  api_version = local.api_version

  api_gw_log_retetion = local.api_gw_log_retention

  create_custom_domain = local.create_api_custom_domain
  certificate_domain   = local.certificate_domain
  custom_sub_domain    = local.api_sub_domain

  tags = local.tags
}