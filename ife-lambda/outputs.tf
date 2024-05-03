output "authorization_lambda_arn" {
  value = aws_lambda_function.ife_lambda_authorizer.arn
}

output "authorization_lambda_invoke_arn" {
  value = aws_lambda_function.ife_lambda_authorizer.invoke_arn
}
