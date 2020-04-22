terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = ">= 2.27"
  region  = var.region
}

module "ife" {
  source = "../../"

  ife_configuration = jsondecode(file("./ife-configuration-dev.json"))

  region      = var.region
  environment = "dev"
  name        = "ife"
  project     = "my-project"

  #COGNITO
  pool_name          = "IFE"
  cognito_sub_domain = "ife"


  #API GATEWAY
  api_version = 1.0
  root_path   = "api"
  nlb_arn     = "arn:aws:elasticloadbalancing:eu-west-1:..."

  api_gw_log_retetion = 7

  create_api_custom_domain = false

  #LAMBDA
  lambda_log_retention = 30
}
