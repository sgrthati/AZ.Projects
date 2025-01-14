# Archive a single file.
data "archive_file" "init" {
  type        = "zip"
  source_file = "./supporting_files/lambda_function.py"
  output_path = "./supporting_files/files/init.zip"
}
# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
}
resource "aws_iam_role_policy_attachment" "lambda_basic_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
#lambda
resource "aws_lambda_function" "soap_transformer" {
  function_name = "soap-transformer"
  filename      = data.archive_file.init.output_path
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec_role.arn
  layers = [aws_lambda_layer_version.name.arn]
  environment {
    variables = {
      SOAP_ENDPOINT = local.URL
      SOAP_VERSION  = "1.2" # Pass SOAP version dynamically
    }
  }
}
resource "aws_lambda_layer_version" "name" {
  layer_name = "requests"
  filename = "./supporting_files/files/requests.zip"
  compatible_runtimes = ["python3.12"]
}
resource "aws_lambda_permission" "api_gw_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soap_transformer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.execution_arn}/*"
}
