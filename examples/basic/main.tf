terraform {
  required_version = ">= 0.13"
}

provider "aws" {
  region = var.region
}

module "template" {
  source      = "../../"
  environment = "dev"
  region      = "eu-west-1"

  ife_configuration = jsondecode(file("./ife-configuration-dev.json"))

  #COGNITO
  pool_name          = "IFE"
  cognito_sub_domain = "ife"

  #API GATEWAY
  api_version = 1.0
  nlb_arn     = "arn:aws:elasticloadbalancing:eu-west-1:..."

}

