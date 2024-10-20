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


# API Gateway
# API Gateway Rest API
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
    aws_api_gateway_integration.post_lambda_integration
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

