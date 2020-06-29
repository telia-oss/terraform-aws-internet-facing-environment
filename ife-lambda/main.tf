locals {
  ife_authorization_lambda_name = "ife-authorization-lambda"
}

data "archive_file" "authorization_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-functions/${local.ife_authorization_lambda_name}"
  output_path = "${path.module}/lambda-functions/${local.ife_authorization_lambda_name}.zip"
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${local.ife_authorization_lambda_name}"
  retention_in_days = var.lambda_log_retention

  tags = var.tags
}

data "aws_iam_policy_document" "ife_lambda_assume" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "ife_lambda_role" {
  name               = "${local.ife_authorization_lambda_name}_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.ife_lambda_assume.json

  tags = var.tags
}

resource "aws_iam_role_policy" "ife_lambda_policy" {
  name   = "${local.ife_authorization_lambda_name}_lambda_policy"
  role   = aws_iam_role.ife_lambda_role.name
  policy = data.aws_iam_policy_document.ife_lambda_policy_document.json
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ife_lambda_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "ecs:*",
      "cloudwatch:*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }

  statement {
    effect    = "Allow"
    resources = formatlist("arn:aws:ssm:%s:%s:parameter/%s/*", var.env_region, data.aws_caller_identity.current.account_id, var.param_store_client_prefix)
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
  }
}

resource "aws_lambda_function" "ife_lambda_authorizer" {
  function_name = local.ife_authorization_lambda_name
  description   = "API GW custom authroziation lambda"
  filename      = data.archive_file.authorization_lambda_zip.output_path
  memory_size   = 1024
  timeout       = 30

  runtime          = "nodejs12.x"
  role             = aws_iam_role.ife_lambda_role.arn
  source_code_hash = data.archive_file.authorization_lambda_zip.output_base64sha256
  handler          = "src/authorizer.handler"

  environment {
    variables = {
      REGION             = var.env_region
      USER_POOL_ID       = var.env_user_pool_id
      PARAM_STORE_PREFIX = var.param_store_client_prefix
    }
  }

  tags = var.tags

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = var.lambda_security_group_ids
  }
}
