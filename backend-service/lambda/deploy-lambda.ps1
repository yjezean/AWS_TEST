# PowerShell script to deploy Lambda functions to AWS

param(
    [string]$Region = "us-east-1",
    [string]$FunctionName = "image-processing-api"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying Lambda Function" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Region: $Region"
Write-Host "Function: $FunctionName"
Write-Host "========================================" -ForegroundColor Cyan

# Check if deployment package exists
if (-not (Test-Path "lambda-deployment.zip")) {
    Write-Host "Error: lambda-deployment.zip not found!" -ForegroundColor Red
    Write-Host "Run package-lambda.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Check if function exists
Write-Host "`nChecking if function exists..."
try {
    aws lambda get-function --function-name $FunctionName --region $Region 2>$null
    $functionExists = $true
} catch {
    $functionExists = $false
}

if ($functionExists) {
    Write-Host "Function exists, updating code..." -ForegroundColor Yellow
    
    # Update function code
    aws lambda update-function-code `
        --function-name $FunctionName `
        --zip-file fileb://lambda-deployment.zip `
        --region $Region
    
    Write-Host "Function code updated successfully" -ForegroundColor Green
} else {
    Write-Host "Function does not exist, creating..." -ForegroundColor Yellow
    
    # Get AWS Account ID
    $accountId = aws sts get-caller-identity --query Account --output text
    
    # Create function
    aws lambda create-function `
        --function-name $FunctionName `
        --runtime python3.10 `
        --role "arn:aws:iam::${accountId}:role/lambda-execution-role" `
        --handler lambda_handler.lambda_handler `
        --zip-file fileb://lambda-deployment.zip `
        --timeout 30 `
        --memory-size 512 `
        --region $Region `
        --environment "Variables={SQS_QUEUE_URL=https://sqs.${Region}.amazonaws.com/${accountId}/image-processing-queue,JOBS_TABLE_NAME=image-processing-jobs,S3_BUCKET=image-processing-uploads}"
    
    Write-Host "Function created successfully" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Get function ARN
$functionArn = aws lambda get-function `
    --function-name $FunctionName `
    --region $Region `
    --query 'Configuration.FunctionArn' `
    --output text

Write-Host "Function ARN: $functionArn"
Write-Host ""
Write-Host "To test the function:" -ForegroundColor Yellow
Write-Host "  aws lambda invoke --function-name $FunctionName output.json" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green

