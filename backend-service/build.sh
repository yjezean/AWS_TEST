#!/bin/bash

# Build script for YOLOv11 Detection Service Docker image
# Usage: ./build.sh [IMAGE_NAME] [TAG]

set -e

# Default values
IMAGE_NAME=${1:-"yolov11-detector"}
TAG=${2:-"latest"}

echo "========================================"
echo "Building Docker Image"
echo "========================================"
echo "Image Name: $IMAGE_NAME"
echo "Tag: $TAG"
echo "========================================"

# Build the Docker image
docker build \
    --tag ${IMAGE_NAME}:${TAG} \
    --file Dockerfile \
    --progress=plain \
    .

echo "========================================"
echo "Build Complete!"
echo "========================================"
echo "Image: ${IMAGE_NAME}:${TAG}"
echo ""
echo "To run locally:"
echo "  docker run -p 8000:8000 ${IMAGE_NAME}:${TAG}"
echo ""
echo "To test:"
echo "  curl http://localhost:8000/health"
echo "========================================"

