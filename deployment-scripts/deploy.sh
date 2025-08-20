#!/bin/bash

# AWS Mobile App Deployment Script
# This script automates the deployment of the AWS infrastructure and Flutter app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="aws-mobile-app"
REGION="us-east-1"
ENVIRONMENT="dev"

echo -e "${BLUE}🚀 Starting AWS Mobile App Deployment${NC}"
echo "=================================="

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}📋 Checking prerequisites...${NC}"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
        exit 1
    fi
    
    # Check Amplify CLI
    if ! command -v amplify &> /dev/null; then
        echo -e "${RED}❌ Amplify CLI is not installed. Please install it first.${NC}"
        exit 1
    fi
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}❌ Flutter is not installed. Please install it first.${NC}"
        exit 1
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js is not installed. Please install it first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites are installed${NC}"
}

# Configure AWS credentials
configure_aws() {
    echo -e "${YELLOW}🔧 Configuring AWS credentials...${NC}"
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${YELLOW}⚠️  AWS credentials not configured. Please run 'aws configure' first.${NC}"
        read -p "Press Enter to continue after configuring AWS credentials..."
    fi
    
    echo -e "${GREEN}✅ AWS credentials configured${NC}"
}

# Create S3 buckets
create_s3_buckets() {
    echo -e "${YELLOW}🪣 Creating S3 buckets...${NC}"
    
    # Create bucket for images
    IMAGES_BUCKET="${PROJECT_NAME}-images-$(date +%s)"
    aws s3 mb s3://${IMAGES_BUCKET} --region ${REGION}
    
    # Create bucket for ML models
    MODELS_BUCKET="${PROJECT_NAME}-models-$(date +%s)"
    aws s3 mb s3://${MODELS_BUCKET} --region ${REGION}
    
    # Configure CORS for images bucket
    cat > cors.json << EOF
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "POST", "PUT"],
        "AllowedOrigins": ["*"],
        "ExposeHeaders": []
    }
]
EOF
    
    aws s3api put-bucket-cors --bucket ${IMAGES_BUCKET} --cors-configuration file://cors.json
    
    echo -e "${GREEN}✅ S3 buckets created:${NC}"
    echo "   Images: ${IMAGES_BUCKET}"
    echo "   Models: ${MODELS_BUCKET}"
    
    # Save bucket names for later use
    echo "IMAGES_BUCKET=${IMAGES_BUCKET}" > .env
    echo "MODELS_BUCKET=${MODELS_BUCKET}" >> .env
}

# Setup Amplify project
setup_amplify() {
    echo -e "${YELLOW}⚡ Setting up Amplify project...${NC}"
    
    cd mobile-app
    
    # Initialize Amplify
    amplify init \
        --app ${PROJECT_NAME} \
        --envName ${ENVIRONMENT} \
        --defaultEditor code \
        --framework flutter \
        --yes
    
    # Add authentication
    amplify add auth \
        --default \
        --yes
    
    # Add storage
    amplify add storage \
        --default \
        --yes
    
    # Add API
    amplify add api \
        --default \
        --yes
    
    # Push changes
    amplify push --yes
    
    cd ..
    
    echo -e "${GREEN}✅ Amplify project configured${NC}"
}

# Deploy Lambda function
deploy_lambda() {
    echo -e "${YELLOW}🔧 Deploying Lambda function...${NC}"
    
    cd backend/lambda/imageProcessor
    
    # Install dependencies
    npm install
    
    # Create deployment package
    zip -r function.zip .
    
    # Create Lambda function
    aws lambda create-function \
        --function-name ${PROJECT_NAME}-image-processor \
        --runtime nodejs18.x \
        --role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/lambda-execution-role \
        --handler index.handler \
        --zip-file fileb://function.zip \
        --timeout 300 \
        --memory-size 1024 \
        --environment Variables="{PINPOINT_APP_ID=your-pinpoint-app-id}" \
        --region ${REGION}
    
    cd ../../..
    
    echo -e "${GREEN}✅ Lambda function deployed${NC}"
}

# Setup Amazon Pinpoint
setup_pinpoint() {
    echo -e "${YELLOW}📱 Setting up Amazon Pinpoint...${NC}"
    
    # Create Pinpoint app
    PINPOINT_APP_ID=$(aws pinpoint create-app \
        --name "${PROJECT_NAME}-notifications" \
        --region ${REGION} \
        --query ApplicationId \
        --output text)
    
    echo "PINPOINT_APP_ID=${PINPOINT_APP_ID}" >> .env
    
    echo -e "${GREEN}✅ Pinpoint app created: ${PINPOINT_APP_ID}${NC}"
}

# Build and deploy Flutter app
deploy_flutter() {
    echo -e "${YELLOW}📱 Building Flutter app...${NC}"
    
    cd mobile-app
    
    # Get dependencies
    flutter pub get
    
    # Build for web
    flutter build web
    
    # Deploy to Amplify
    amplify publish --yes
    
    cd ..
    
    echo -e "${GREEN}✅ Flutter app deployed${NC}"
}

# Upload YOLOv11 model
upload_model() {
    echo -e "${YELLOW}🤖 Uploading YOLOv11 model...${NC}"
    
    # Download YOLOv11 model (if not exists)
    if [ ! -f "ml-model/yolov11n.pt" ]; then
        echo "Downloading YOLOv11 model..."
        mkdir -p ml-model
        cd ml-model
        wget https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov11n.pt
        cd ..
    fi
    
    # Upload to S3
    source .env
    aws s3 cp ml-model/yolov11n.pt s3://${MODELS_BUCKET}/yolov11n.pt
    
    echo -e "${GREEN}✅ YOLOv11 model uploaded${NC}"
}

# Main deployment function
main() {
    echo -e "${BLUE}🎯 Starting deployment process...${NC}"
    
    check_prerequisites
    configure_aws
    create_s3_buckets
    setup_amplify
    deploy_lambda
    setup_pinpoint
    upload_model
    deploy_flutter
    
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo "1. Configure your Flutter app with the generated Amplify configuration"
    echo "2. Update the Lambda function with your Pinpoint App ID"
    echo "3. Test the application flow"
    echo "4. Set up monitoring and logging"
    echo ""
    echo -e "${YELLOW}📁 Configuration files saved to .env${NC}"
}

# Run main function
main "$@"
