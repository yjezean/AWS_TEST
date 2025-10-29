#!/bin/bash

# Deploy YOLOv11 Docker image to AWS ECR
# Usage: ./deploy-to-ecr.sh [AWS_REGION] [AWS_ACCOUNT_ID] [REPOSITORY_NAME]

set -e

# Configuration
AWS_REGION=${1:-"us-east-1"}
AWS_ACCOUNT_ID=${2:-""}
REPOSITORY_NAME=${3:-"yolov11-detector"}
IMAGE_TAG=${4:-"latest"}

# Validate AWS Account ID
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "ERROR: AWS Account ID is required!"
    echo "Usage: ./deploy-to-ecr.sh AWS_REGION AWS_ACCOUNT_ID [REPOSITORY_NAME] [IMAGE_TAG]"
    echo "Example: ./deploy-to-ecr.sh us-east-1 123456789012 yolov11-detector latest"
    exit 1
fi

ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
FULL_IMAGE_NAME="${ECR_URI}/${REPOSITORY_NAME}:${IMAGE_TAG}"

echo "========================================"
echo "Deploying to AWS ECR"
echo "========================================"
echo "Region: $AWS_REGION"
echo "Account ID: $AWS_ACCOUNT_ID"
echo "Repository: $REPOSITORY_NAME"
echo "Tag: $IMAGE_TAG"
echo "Full Image: $FULL_IMAGE_NAME"
echo "========================================"

# Step 1: Create ECR repository if it doesn't exist
echo "Step 1: Checking/Creating ECR repository..."
aws ecr describe-repositories \
    --repository-names ${REPOSITORY_NAME} \
    --region ${AWS_REGION} 2>/dev/null || \
aws ecr create-repository \
    --repository-name ${REPOSITORY_NAME} \
    --region ${AWS_REGION} \
    --image-scanning-configuration scanOnPush=true

# Step 2: Authenticate Docker to ECR
echo "Step 2: Authenticating Docker to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${ECR_URI}

# Step 3: Build the Docker image
echo "Step 3: Building Docker image..."
docker build -t ${REPOSITORY_NAME}:${IMAGE_TAG} .

# Step 4: Tag the image for ECR
echo "Step 4: Tagging image..."
docker tag ${REPOSITORY_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}

# Step 5: Push to ECR
echo "Step 5: Pushing to ECR..."
docker push ${FULL_IMAGE_NAME}

echo "========================================"
echo "Deployment Complete!"
echo "========================================"
echo "Image pushed to: $FULL_IMAGE_NAME"
echo ""
echo "Next steps:"
echo "1. Create ECS cluster (if not exists)"
echo "2. Create task definition using this image"
echo "3. Create ECS service"
echo ""
echo "To pull this image:"
echo "  docker pull $FULL_IMAGE_NAME"
echo "========================================"

