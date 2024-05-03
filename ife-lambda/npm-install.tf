locals {
  lambda_path = "${path.module}/lambda-functions/ife-authorization-lambda/src"
}

#
# Store sha-sums of the files in terraform state to detect file changes.
#
resource "null_resource" "lambda_dependencies" {
  provisioner "local-exec" {
    command = "cd ${path.module}/lambda-functions/ife-authorization-lambda/src && npm install"
  }

  triggers = {
    authUtils    = sha256(file("${local.lambda_path}/authUtils.js"))
    authorizer   = sha256(file("${local.lambda_path}/authorizer.js"))
    basicAuth    = sha256(file("${local.lambda_path}/basicAuth.js"))
    bearerAuth   = sha256(file("${local.lambda_path}/bearerAuth.js"))
    package      = sha256(file("${local.lambda_path}/package.json"))
    lock         = sha256(file("${local.lambda_path}/package-lock.json"))
    node_modules = sha256(join("", fileset(local.lambda_path, "node_modules/**/*.js")))
  }
}

#
# Enforce order for terraform and ensure null_resource.lambda_dependencies executes
# before archive_file.authorization_lambda_zip.
#
data "null_data_source" "wait_for_lambda_exporter" {
  inputs = {
    lambda_dependency_id = "${null_resource.lambda_dependencies.id}"
    source_dir           = "${path.module}/lambda-functions/ife-authorization-lambda"
  }
}
