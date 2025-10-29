#!/bin/bash

# Deploy Lambda functions to AWS
# Usage: ./deploy-lambda.sh [AWS_REGION] [FUNCTION_NAME]

set -e

AWS_REGION=${1:-"us-east-1"}
FUNCTION_NAME=${2:-"image-processing-api"}

echo "========================================"
echo "Deploying Lambda Function"
echo "========================================"
echo "Region: $AWS_REGION"
echo "Function: $FUNCTION_NAME"
echo "========================================"

# Check if function exists
echo "Checking if function exists..."
if aws lambda get-function --function-name $FUNCTION_NAME --region $AWS_REGION 2>/dev/null; then
    echo "Function exists, updating code..."
    
    # Update function code
    aws lambda update-function-code \
        --function-name $FUNCTION_NAME \
        --zip-file fileb://lambda-deployment.zip \
        --region $AWS_REGION
    
    echo "Function code updated successfully"
else
    echo "Function does not exist, creating..."
    
    # Create function
    aws lambda create-function \
        --function-name $FUNCTION_NAME \
        --runtime python3.10 \
        --role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/lambda-execution-role \
        --handler lambda_handler.lambda_handler \
        --zip-file fileb://lambda-deployment.zip \
        --timeout 30 \
        --memory-size 512 \
        --region $AWS_REGION \
        --environment Variables={
            SQS_QUEUE_URL=https://sqs.$AWS_REGION.amazonaws.com/ACCOUNT_ID/image-processing-queue,
            JOBS_TABLE_NAME=image-processing-jobs,
            S3_BUCKET=image-processing-uploads
        }
    
    echo "Function created successfully"
fi

echo "========================================"
echo "Deployment Complete!"
echo "========================================"
echo "Function ARN:"
aws lambda get-function \
    --function-name $FUNCTION_NAME \
    --region $AWS_REGION \
    --query 'Configuration.FunctionArn' \
    --output text

echo ""
echo "To test the function:"
echo "  aws lambda invoke --function-name $FUNCTION_NAME output.json"
echo "========================================"

