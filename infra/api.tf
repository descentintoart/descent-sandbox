# ---------- Lambda ----------

# Zips the folder that apps/ulid/api/build.sh fills.
data "archive_file" "ulid_api" {
  type        = "zip"
  source_dir  = "${path.module}/../apps/ulid/api/build"
  output_path = "${path.module}/.build/ulid-api.zip"
}

resource "aws_iam_role" "ulid_api" {
  name = "sandbox-ulid-api"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Lets the function write its own logs, nothing else.
resource "aws_iam_role_policy_attachment" "ulid_api_logs" {
  role       = aws_iam_role.ulid_api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "ulid_api" {
  name              = "/aws/lambda/sandbox-ulid-api"
  retention_in_days = 14
}

resource "aws_lambda_function" "ulid_api" {
  function_name    = "sandbox-ulid-api"
  role             = aws_iam_role.ulid_api.arn
  runtime          = "python3.13"
  architectures    = ["arm64"]
  handler          = "handler.handler"
  filename         = data.archive_file.ulid_api.output_path
  source_code_hash = data.archive_file.ulid_api.output_base64sha256
  memory_size      = 128
  timeout          = 5

  depends_on = [
    aws_iam_role_policy_attachment.ulid_api_logs,
    aws_cloudwatch_log_group.ulid_api,
  ]
}

# ---------- API Gateway (HTTP API) ----------

resource "aws_apigatewayv2_api" "ulid" {
  name          = "sandbox-ulid"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "ulid" {
  api_id                 = aws_apigatewayv2_api.ulid.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.ulid_api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "mint" {
  api_id    = aws_apigatewayv2_api.ulid.id
  route_key = "GET /api/ulid"
  target    = "integrations/${aws_apigatewayv2_integration.ulid.id}"
}

resource "aws_apigatewayv2_route" "decode" {
  api_id    = aws_apigatewayv2_api.ulid.id
  route_key = "GET /api/ulid/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.ulid.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.ulid.id
  name        = "$default"
  auto_deploy = true

  # Caps traffic so a runaway script can't run up a bill.
  default_route_settings {
    throttling_burst_limit = 20
    throttling_rate_limit  = 10
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ulid_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ulid.execution_arn}/*/*"
}
