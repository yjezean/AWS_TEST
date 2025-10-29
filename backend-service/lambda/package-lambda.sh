#!/bin/bash

# Package Lambda function for deployment
# This creates a deployment ZIP with all dependencies

set -e

echo "========================================"
echo "Packaging Lambda Function"
echo "========================================"

# Create build directory
BUILD_DIR="lambda-build"
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

echo "Installing Python dependencies..."
pip install -t $BUILD_DIR boto3 python-dotenv

echo "Copying Lambda handler..."
cp lambda_handler.py $BUILD_DIR/

echo "Creating deployment package..."
cd $BUILD_DIR
zip -r ../lambda-deployment.zip .
cd ..

echo "========================================"
echo "Lambda package created: lambda-deployment.zip"
echo "Size: $(du -h lambda-deployment.zip | cut -f1)"
echo "========================================"
echo ""
echo "To deploy to AWS Lambda:"
echo "  aws lambda update-function-code \\"
echo "    --function-name image-processing-api \\"
echo "    --zip-file fileb://lambda-deployment.zip"
echo "========================================"

# Cleanup
rm -rf $BUILD_DIR

