provider "aws" {
  region = "us-east-1"
}

# DynamoDB Table
resource "aws_dynamodb_table" "fragrance_table" {
  name         = "FragrancePrices"
  billing_mode = "PAY_PER_REQUEST"
  
  hash_key     = "fragrance_name"
  range_key    = "store_name"

  attribute {
    name = "fragrance_name"
    type = "S"
  }

  attribute {
    name = "store_name"
    type = "S"
  }
}

# DynamoDB Table for scentSearchUserData
resource "aws_dynamodb_table" "scent_search_user_data" {
  name         = "scentSearchUserData"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "user_id" # Primary key for the table

  attribute {
    name = "user_id"
    type = "S" # String type
  }

  tags = {
    Environment = "Production"
    Application = "ScentSearch"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-dynamodb-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Role Policy to allow Lambda access to DynamoDB
resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query"
        ],
        Resource = "arn:aws:dynamodb:us-east-1:055334129181:table/FragrancePrices"
      }
    ]
  })
}

# Lambda function for 'get_fragrances'
resource "aws_lambda_function" "get_fragrances" {
  function_name = "GetFragrances"
  runtime       = "nodejs18.x"
  handler       = "get.handler"

  filename         = "lambdas.zip"
  source_code_hash = filebase64sha256("lambdas.zip")
  role             = aws_iam_role.lambda_role.arn
}

# Lambda function for 'seed_fragrances'
resource "aws_lambda_function" "seed_fragrances" {
  function_name = "SeedFragrances"
  runtime       = "nodejs18.x"
  handler       = "seed.handler"

  filename         = "lambdas.zip"
  source_code_hash = filebase64sha256("lambdas.zip")
  role             = aws_iam_role.lambda_role.arn
}

resource "aws_lambda_function" "update_fragrance" {
  function_name = "UpdateFragrance"
  runtime       = "nodejs18.x"
  handler       = "updateFragrance.handler"
  filename      = "lambdas.zip"
  source_code_hash = filebase64sha256("lambdas.zip")
  role          = aws_iam_role.lambda_role.arn
}

# Lambda function for 'get_all_fragrances'
resource "aws_lambda_function" "get_all_fragrances" {
  function_name = "GetAllFragrances"
  runtime       = "nodejs18.x"
  handler       = "getAllFragrances.handler"

  filename         = "lambdas.zip"
  source_code_hash = filebase64sha256("lambdas.zip")
  role             = aws_iam_role.lambda_role.arn
}

# API Gateway
resource "aws_api_gateway_rest_api" "fragrance_api" {
  name        = "FragranceAPI"
  description = "API for retrieving and seeding fragrance data"
}

# API Gateway Resource for /fragrances
resource "aws_api_gateway_resource" "fragrance_resource" {
  rest_api_id = aws_api_gateway_rest_api.fragrance_api.id
  parent_id   = aws_api_gateway_rest_api.fragrance_api.root_resource_id
  path_part   = "fragrances"
}

# Method: GET /fragrances
resource "aws_api_gateway_method" "get_fragrances_method" {
  rest_api_id   = aws_api_gateway_rest_api.fragrance_api.id
  resource_id   = aws_api_gateway_resource.fragrance_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Integration: Connect GET /fragrances to Lambda
resource "aws_api_gateway_integration" "get_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.fragrance_api.id
  resource_id = aws_api_gateway_resource.fragrance_resource.id
  http_method = aws_api_gateway_method.get_fragrances_method.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.get_fragrances.invoke_arn
}

# Method: POST /fragrances (to seed data)
resource "aws_api_gateway_method" "post_fragrances_method" {
  rest_api_id   = aws_api_gateway_rest_api.fragrance_api.id
  resource_id   = aws_api_gateway_resource.fragrance_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integration: Connect POST /fragrances to Lambda
resource "aws_api_gateway_integration" "post_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.fragrance_api.id
  resource_id = aws_api_gateway_resource.fragrance_resource.id
  http_method = aws_api_gateway_method.post_fragrances_method.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.seed_fragrances.invoke_arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.get_lambda_integration,
    aws_api_gateway_integration.post_lambda_integration,
    aws_api_gateway_integration.options_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.fragrance_api.id
  stage_name  = "prod"
}

resource "aws_api_gateway_resource" "fragrance_update_resource" {
  rest_api_id = aws_api_gateway_rest_api.fragrance_api.id
  parent_id   = aws_api_gateway_resource.fragrance_resource.id  # This is the parent "/fragrances"
  path_part   = "update"
}

resource "aws_api_gateway_method" "post_update_fragrance_method" {
  rest_api_id   = aws_api_gateway_rest_api.fragrance_api.id
  resource_id   = aws_api_gateway_resource.fragrance_update_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_lambda_permission" "apigw_invoke_update_lambda" {
  statement_id  = "AllowAPIGatewayInvokeUpdate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_fragrance.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.fragrance_api.execution_arn}/*/*"
}

resource "aws_api_gateway_integration" "update_fragrance_lambda_integration" {
  rest_api_id            = aws_api_gateway_rest_api.fragrance_api.id
  resource_id            = aws_api_gateway_resource.fragrance_update_resource.id
  http_method            = aws_api_gateway_method.post_update_fragrance_method.http_method
  type                   = "AWS_PROXY"
  integration_http_method = "POST"
  uri                    = aws_lambda_function.update_fragrance.invoke_arn
}

resource "aws_lambda_permission" "apigw_invoke_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_fragrances.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.fragrance_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_invoke_seed_lambda" {
  statement_id  = "AllowAPIGatewayInvokeSeed"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.seed_fragrances.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.fragrance_api.execution_arn}/*/*"
}

# Enable CORS for GET and POST methods
resource "aws_api_gateway_method_response" "get_method_response" {
  rest_api_id = aws_api_gateway_rest_api.fragrance_api.id
  resource_id = aws_api_gateway_resource.fragrance_resource.id
  http_method = aws_api_gateway_method.get_fragrances_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "get_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.fragrance_api.id
  resource_id = aws_api_gateway_resource.fragrance_resource.id
  http_method = aws_api_gateway_method.get_fragrances_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_method_response" "post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.fragrance_api.id
  resource_id = aws_api_gateway_resource.fragrance_resource.id
  http_method = aws_api_gateway_method.post_fragrances_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.fragrance_api.id
  resource_id = aws_api_gateway_resource.fragrance_resource.id
  http_method = aws_api_gateway_method.post_fragrances_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

# OPTIONS method to handle CORS preflight requests
resource "aws_api_gateway_method" "options_fragrances_method" {
  rest_api_id   = aws_api_gateway_rest_api.fragrance_api.id
  resource_id   = aws_api_gateway_resource.fragrance_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id            = aws_api_gateway_rest_api.fragrance_api.id
  resource_id            = aws_api_gateway_resource.fragrance_resource.id
  http_method            = aws_api_gateway_method.options_fragrances_method.http_method
  type                   = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  integration_http_method = "POST"
}

resource "aws_api_gateway_method_response" "options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.fragrance_api.id
  resource_id = aws_api_gateway_resource.fragrance_resource.id
  http_method = aws_api_gateway_method.options_fragrances_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  depends_on = [aws_api_gateway_integration.options_integration]  # Ensure integration is created first
  rest_api_id = aws_api_gateway_rest_api.fragrance_api.id
  resource_id = aws_api_gateway_resource.fragrance_resource.id
  http_method = aws_api_gateway_method.options_fragrances_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
  }
}

# API Gateway Resource for /fragrances/all
resource "aws_api_gateway_resource" "all_fragrances_resource" {
  rest_api_id = aws_api_gateway_rest_api.fragrance_api.id
  parent_id   = aws_api_gateway_resource.fragrance_resource.id  # Parent is /fragrances
  path_part   = "all"
}

# Method: GET /fragrances/all
resource "aws_api_gateway_method" "get_all_fragrances_method" {
  rest_api_id   = aws_api_gateway_rest_api.fragrance_api.id
  resource_id   = aws_api_gateway_resource.all_fragrances_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Integration: Connect GET /fragrances/all to Lambda
resource "aws_api_gateway_integration" "get_all_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.fragrance_api.id
  resource_id = aws_api_gateway_resource.all_fragrances_resource.id
  http_method = aws_api_gateway_method.get_all_fragrances_method.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.get_all_fragrances.invoke_arn
}

# Lambda permission for the new endpoint
resource "aws_lambda_permission" "apigw_invoke_get_all_lambda" {
  statement_id  = "AllowAPIGatewayInvokeGetAll"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_all_fragrances.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.fragrance_api.execution_arn}/*/*"
}
