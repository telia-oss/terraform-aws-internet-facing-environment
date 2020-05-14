locals {

  mapping_by_scope_path = {
    for mapping in var.ife_configuration.mappings : mapping.scope_path => mapping if mapping.enabled == true
  }

}

resource "aws_api_gateway_rest_api" "ife_rest_api" {
  name        = "IFE-API-Gateway"
  description = "IFE Gateway to expose internal/private enpoints"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_authorizer" "custom_lambda_authorizer" {
  name          = "IFE_custom_lambda_authorizer"
  type          = "TOKEN"
  rest_api_id   = aws_api_gateway_rest_api.ife_rest_api.id
  provider_arns = [var.cognito_user_pool_arn]

  authorizer_result_ttl_in_seconds = 0

  authorizer_uri         = var.authorization_lambda_invoke_arn
  authorizer_credentials = aws_iam_role.ife_api_gateway_invocation_role.arn
}

resource "aws_iam_role" "ife_api_gateway_invocation_role" {
  name = "ife-api-gateway_invocation_role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = var.tags
}

resource "aws_iam_role_policy" "api_gateway_invocation_policy" {
  name = "ife-api-gateway-invocation_policy"
  role = aws_iam_role.ife_api_gateway_invocation_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${var.authorization_lambda_arn}"
    }
  ]
}
EOF
}

resource "aws_api_gateway_vpc_link" "ife_vpc_link" {
  name        = "IFE-VPC-link"
  description = "API GW VPC link to Network ALB"
  target_arns = [var.nlb_arn]

  tags = var.tags
}


resource "aws_api_gateway_resource" "ife_api_proxy" {
  for_each = local.mapping_by_scope_path

  rest_api_id = aws_api_gateway_rest_api.ife_rest_api.id
  parent_id   = aws_api_gateway_rest_api.ife_rest_api.root_resource_id
  path_part   = each.value.scope_path
}


data "aws_api_gateway_resource" "ife_api_proxy_resources" {
  for_each = local.mapping_by_scope_path

  rest_api_id = aws_api_gateway_rest_api.ife_rest_api.id
  path        = "/${each.value.scope_path}"

  depends_on = [aws_api_gateway_resource.ife_api_proxy]
}

resource "aws_api_gateway_resource" "ife_path_proxy" {
  for_each = data.aws_api_gateway_resource.ife_api_proxy_resources

  rest_api_id = aws_api_gateway_rest_api.ife_rest_api.id
  parent_id   = each.value.id
  path_part   = "{proxy+}"
}

data "aws_api_gateway_resource" "ife_path_proxy_resources" {
  for_each = local.mapping_by_scope_path

  rest_api_id = aws_api_gateway_rest_api.ife_rest_api.id
  path        = "/${each.value.scope_path}/{proxy+}"

  depends_on = [aws_api_gateway_resource.ife_path_proxy]
}

resource "aws_api_gateway_method" "any" {
  for_each = data.aws_api_gateway_resource.ife_path_proxy_resources

  rest_api_id   = aws_api_gateway_rest_api.ife_rest_api.id
  resource_id   = each.value.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_lambda_authorizer.id

  request_parameters = {
    "method.request.path.proxy" = true
  }

  lifecycle {
    ignore_changes = [resource_id]
  }

  depends_on = [aws_api_gateway_resource.ife_path_proxy]
}

resource "aws_api_gateway_integration" "ife_vpc_link_integration" {
  for_each = data.aws_api_gateway_resource.ife_path_proxy_resources

  rest_api_id             = aws_api_gateway_rest_api.ife_rest_api.id
  resource_id             = each.value.id
  http_method             = "ANY"
  integration_http_method = "ANY"

  type = "HTTP_PROXY"
  uri  = lookup(local.mapping_by_scope_path, element(split("/", each.value.path), 1), null).target

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.ife_vpc_link.id

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  lifecycle {
    ignore_changes = [resource_id]
  }

  depends_on = [aws_api_gateway_method.any]
}


resource "aws_api_gateway_deployment" "ife_deployment" {
  rest_api_id = aws_api_gateway_rest_api.ife_rest_api.id
  stage_name  = var.stage_name

  variables = {
    version = var.api_version
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_method.any, aws_api_gateway_integration.ife_vpc_link_integration]
}


# CLOUDWATCH LOGGING
/*
commented due to bug https://github.com/terraform-providers/terraform-provider-aws/issues/10105
resource "aws_api_gateway_stage" "ife_stage" {
  stage_name = var.stage_name
  deployment_id = aws_api_gateway_deployment.ife_deployment.id
  rest_api_id = aws_api_gateway_rest_api.ife_rest_api.id

  depends_on = [aws_cloudwatch_log_group.ife_api_gw_log]
}

resource "aws_api_gateway_method_settings" "s" {
  rest_api_id = aws_api_gateway_rest_api.ife_rest_api.id
  stage_name  = aws_api_gateway_stage.ife_stage.stage_name
  method_path = "*"
/
/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}
*/


resource "aws_cloudwatch_log_group" "ife_api_gw_log" {
  name              = "IFE-API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.ife_rest_api.id}/${var.stage_name}"
  retention_in_days = var.api_gw_log_retetion
  tags              = var.tags
}

resource "aws_api_gateway_account" "ife_api_gw_account" {
  cloudwatch_role_arn = aws_iam_role.ife_api_gateway_invocation_role.arn
}


resource "aws_iam_role_policy" "ife_api_gw_cloudwatch_policy" {
  name = "ife_api_gw_cloudwatch_policy"
  role = aws_iam_role.ife_api_gateway_invocation_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

#DOMAIN CONFIGURATION
resource "aws_api_gateway_base_path_mapping" "ife_base_path_mapping" {
  count       = var.create_custom_domain == true ? 1 : 0
  api_id      = aws_api_gateway_rest_api.ife_rest_api.id
  stage_name  = aws_api_gateway_deployment.ife_deployment.stage_name
  base_path   = var.root_path
  domain_name = aws_api_gateway_domain_name.ife_api_domain_name[count.index].domain_name

  depends_on = [aws_api_gateway_deployment.ife_deployment]
}

data "aws_acm_certificate" "ife_cerificate" {
  count = var.create_custom_domain == true ? 1 : 0

  domain   = "*.${var.certificate_domain}"
  statuses = ["ISSUED"]
}


resource "aws_api_gateway_domain_name" "ife_api_domain_name" {
  count = var.create_custom_domain == true ? 1 : 0

  regional_certificate_arn = data.aws_acm_certificate.ife_cerificate[count.index].arn
  domain_name              = "${var.custom_sub_domain}.${var.certificate_domain}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

data "aws_route53_zone" "this" {
  count = var.create_custom_domain == true ? 1 : 0

  name = "${var.certificate_domain}."
}

resource "aws_route53_record" "record" {
  count = var.create_custom_domain == true ? 1 : 0

  name    = "${var.custom_sub_domain}.${var.certificate_domain}"
  zone_id = data.aws_route53_zone.this[count.index].zone_id
  type    = "A"

  alias {
    evaluate_target_health = false
    name                   = aws_api_gateway_domain_name.ife_api_domain_name[count.index].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.ife_api_domain_name[count.index].regional_zone_id
  }
}

