# PowerShell script to package Lambda function for deployment

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Packaging Lambda Function" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Create build directory
$BUILD_DIR = "lambda-build"
if (Test-Path $BUILD_DIR) {
    Remove-Item -Recurse -Force $BUILD_DIR
}
New-Item -ItemType Directory -Path $BUILD_DIR | Out-Null

Write-Host "Installing Python dependencies..."
pip install -t $BUILD_DIR boto3 python-dotenv

Write-Host "Copying Lambda handler..."
Copy-Item lambda_handler.py -Destination $BUILD_DIR/

Write-Host "Creating deployment package..."
Push-Location $BUILD_DIR
Compress-Archive -Path * -DestinationPath ../lambda-deployment.zip -Force
Pop-Location

$zipSize = (Get-Item lambda-deployment.zip).Length / 1MB
Write-Host "========================================" -ForegroundColor Green
Write-Host "Lambda package created: lambda-deployment.zip" -ForegroundColor Green
Write-Host "Size: $([math]::Round($zipSize, 2)) MB" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "To deploy to AWS Lambda:" -ForegroundColor Yellow
Write-Host "  aws lambda update-function-code \" -ForegroundColor Yellow
Write-Host "    --function-name image-processing-api \" -ForegroundColor Yellow
Write-Host "    --zip-file fileb://lambda-deployment.zip" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green

# Cleanup
Remove-Item -Recurse -Force $BUILD_DIR

Write-Host "Build directory cleaned up" -ForegroundColor Gray

