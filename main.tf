# Terraform AWS Lambda Deployment

# Configure the AWS provider
provider "aws" {
  region = "us-east-1"  # Update with your desired AWS region
}

# Create an S3 bucket to store the Lambda deployment package
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "lambda-deployment-bucket"  # Update with your desired S3 bucket name
  acl    = "private"
}

# Build the Spring Boot application package
# Update the paths and build commands according to your project structure and build process
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "/path/to/spring-boot-project"
  output_path = "/path/to/spring-boot-project/target/spring-boot-app.zip"

  depends_on = [
    "aws_s3_bucket.lambda_bucket"
  ]
}

# Create the Lambda function
resource "aws_lambda_function" "springboot_lambda" {
  function_name    = "spring-boot-lambda"  # Update with your desired Lambda function name
  handler          = "com.example.MainHandler::handleRequest"  # Update with your application's handler
  runtime          = "java11"
  memory_size      = 512
  timeout          = 30
  role             = aws_iam_role.lambda_role.arn

  s3_bucket        = aws_s3_bucket.lambda_bucket.id
  s3_key           = "spring-boot-app.zip"  # Update if you have a different filename

  source_code_hash = data.archive_file.lambda_package.output_base64sha256

  environment {
    variables = {
      ENV_VAR_1 = "value1"  # Update with your desired environment variables
      ENV_VAR_2 = "value2"
    }
  }
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"  # Update with your desired IAM role name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach a policy to the IAM role to allow basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}
