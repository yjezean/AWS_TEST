# PowerShell script to deploy YOLOv11 Docker image to AWS ECR
# Usage: .\deploy-to-ecr.ps1 -Region "us-east-1" -AccountId "123456789012" -RepositoryName "yolov11-detector"

param(
    [Parameter(Mandatory=$true)]
    [string]$Region,
    
    [Parameter(Mandatory=$true)]
    [string]$AccountId,
    
    [string]$RepositoryName = "yolov11-detector",
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

$EcrUri = "$AccountId.dkr.ecr.$Region.amazonaws.com"
$FullImageName = "$EcrUri/${RepositoryName}:${ImageTag}"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying to AWS ECR" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Region: $Region"
Write-Host "Account ID: $AccountId"
Write-Host "Repository: $RepositoryName"
Write-Host "Tag: $ImageTag"
Write-Host "Full Image: $FullImageName"
Write-Host "========================================" -ForegroundColor Cyan

# Step 1: Create ECR repository if it doesn't exist
Write-Host "`nStep 1: Checking/Creating ECR repository..." -ForegroundColor Yellow
try {
    aws ecr describe-repositories --repository-names $RepositoryName --region $Region 2>$null
    Write-Host "Repository already exists" -ForegroundColor Green
} catch {
    Write-Host "Creating new repository..." -ForegroundColor Yellow
    aws ecr create-repository `
        --repository-name $RepositoryName `
        --region $Region `
        --image-scanning-configuration scanOnPush=true
}

# Step 2: Authenticate Docker to ECR
Write-Host "`nStep 2: Authenticating Docker to ECR..." -ForegroundColor Yellow
$password = aws ecr get-login-password --region $Region
$password | docker login --username AWS --password-stdin $EcrUri

# Step 3: Build the Docker image
Write-Host "`nStep 3: Building Docker image..." -ForegroundColor Yellow
docker build -t "${RepositoryName}:${ImageTag}" .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

# Step 4: Tag the image for ECR
Write-Host "`nStep 4: Tagging image..." -ForegroundColor Yellow
docker tag "${RepositoryName}:${ImageTag}" $FullImageName

# Step 5: Push to ECR
Write-Host "`nStep 5: Pushing to ECR..." -ForegroundColor Yellow
docker push $FullImageName

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Image pushed to: $FullImageName"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Create ECS cluster (if not exists)"
Write-Host "2. Create task definition using this image"
Write-Host "3. Create ECS service"
Write-Host ""
Write-Host "To pull this image:"
Write-Host "  docker pull $FullImageName"
Write-Host "========================================" -ForegroundColor Green

