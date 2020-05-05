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
  count        = var.use_own_domain == false ? 1 : 0
  domain       = var.custom_sub_domain
  user_pool_id = aws_cognito_user_pool.ife_user_pool.id
}

data "aws_route53_zone" "this" {
  count = var.use_own_domain == true ? 1 : 0

  name = "${var.zone_domain_name}."
}

// Small hack as cognito own domain requires existence of A root record
resource "aws_route53_record" "record_root" {
  count = var.use_own_domain == true ? 1 : 0

  name    = var.own_domain
  zone_id = data.aws_route53_zone.this[count.index].zone_id
  type    = "A"
  ttl     = "300"
  records = ["127.0.0.1"]
}

resource "aws_cognito_user_pool_domain" "ife_own_domain" {
  count        = var.use_own_domain == true ? 1 : 0
  certificate_arn = var.certificate_arn
  domain       = "${var.custom_sub_domain}.${var.own_domain}"
  user_pool_id = aws_cognito_user_pool.ife_user_pool.id

  depends_on = [aws_route53_record.record_root]
}

resource "aws_route53_record" "record_ife" {
  count = var.use_own_domain == true ? 1 : 0

  name    = "${var.custom_sub_domain}.${var.own_domain}"
  zone_id = data.aws_route53_zone.this[count.index].zone_id
  type    = "CNAME"
  ttl     = "300"
  records = [aws_cognito_user_pool_domain.ife_own_domain[count.index].cloudfront_distribution_arn]
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