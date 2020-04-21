locals {

  resource_server_config = {
    for rs in var.ife_configuration.mappings : rs.resource_server => rs.scope_path...
  }
}


resource "aws_cognito_user_pool" "ife_user_pool" {
  name = var.cognito_pool_name

  tags = var.tags
}

resource "aws_cognito_user_pool_domain" "ife_generated_domain" {
  domain       = var.custom_sub_domain
  user_pool_id = aws_cognito_user_pool.ife_user_pool.id
}

resource "aws_cognito_resource_server" "ife_resource_server" {
  for_each = local.resource_server_config

  identifier = each.key
  name       = each.key

  user_pool_id = aws_cognito_user_pool.ife_user_pool.id

  dynamic "scope" {
    for_each = each.value
    content {
      scope_name        = scope.value
      scope_description = scope.value
    }
  }
}

resource "aws_cognito_user_pool_client" "client" {
  for_each = { for client in var.ife_configuration.clients : client.name => client }
  name     = each.key

  user_pool_id = aws_cognito_user_pool.ife_user_pool.id

  generate_secret                      = true
  allowed_oauth_flows                  = each.value.allowed_oauth_flows
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = each.value.allowed_scopes

  depends_on = [aws_cognito_resource_server.ife_resource_server]
}