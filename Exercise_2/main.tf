provider "aws" {
  shared_credentials_file="/home/ilex/.aws/credentials"
  region = var.aws_region
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

data "archive_file" "udacity_tf_p2_lambda_code" {
  type        = "zip"
  source_file = "${path.cwd}/greet_lambda.py"
  output_path = "${path.cwd}/lambda.zip"
}

resource "aws_lambda_function" "udacity_tf_p2" {
  filename = "${data.archive_file.udacity_tf_p2_lambda_code.output_path}"
  function_name = "udacity_tf_p2"
  handler = "greet_lambda.lambda_handler"
  runtime = "python3.8"
  role = aws_iam_role.iam_for_lambda.arn

  environment {
    variables = {
      greeting = "Greeting from TF"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs
  ]
}
