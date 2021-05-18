terraform {
  required_version = ">= 0.13"
}

provider "aws" {
  region = "eu-west-1"
}

module "ife" {
  source = "../../"

  ife_configuration = jsondecode(file("./ife-configuration-dev.json"))

  region      = "eu-west-1"
  environment = "dev"
  name        = "ife"
  project     = "my-project"

  #COGNITO
  pool_name          = "IFE"
  cognito_sub_domain = "ife"

  #API GATEWAY
  api_version = 1.0
  nlb_arn     = "arn:aws:elasticloadbalancing:eu-west-1:..."
}
