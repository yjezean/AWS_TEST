# PowerShell build script for YOLOv11 Detection Service
# Usage: .\build.ps1 [IMAGE_NAME] [TAG]

param(
    [string]$ImageName = "yolov11-detector",
    [string]$Tag = "latest"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Docker Image" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Image Name: $ImageName"
Write-Host "Tag: $Tag"
Write-Host "========================================" -ForegroundColor Cyan

# Build the Docker image
docker build `
    --tag "${ImageName}:${Tag}" `
    --file Dockerfile `
    --progress=plain `
    .

if ($LASTEXITCODE -eq 0) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Build Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Image: ${ImageName}:${Tag}"
    Write-Host ""
    Write-Host "To run locally:" -ForegroundColor Yellow
    Write-Host "  docker run -p 8000:8000 ${ImageName}:${Tag}"
    Write-Host ""
    Write-Host "To test:" -ForegroundColor Yellow
    Write-Host "  curl http://localhost:8000/health"
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

