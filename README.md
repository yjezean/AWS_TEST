# AWS Mobile Application with ML Image Detection

## 🚀 Quick Start Deployment

**New to this project? Start here:**

- **[QUICK_START_DEPLOYMENT.md](QUICK_START_DEPLOYMENT.md)** - Build Docker image NOW and deploy step-by-step
- **[DEPLOYMENT_PLAN.md](DEPLOYMENT_PLAN.md)** - Complete deployment plan for AWS Learner Lab
- **[backend-service/README.md](backend-service/README.md)** - Technical architecture details

## Project Overview

A Flutter mobile application that captures images, uploads them to AWS, and processes them through YOLOv11 for object detection using AWS API Gateway.

## Architecture

**Asynchronous Processing Architecture:**

```
┌─────────────────┐
│  Flutter App    │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│    API Gateway (REST)       │
│  POST /upload               │
│  GET  /jobs/{id}            │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  Lambda Function            │
│  - Generate presigned URLs  │
│  - Submit jobs to SQS       │
│  - Query job status         │
└─────┬──────────────┬────────┘
      │              │
      ▼              ▼
┌──────────┐   ┌──────────────┐
│ S3 Bucket│   │  SQS Queue   │
│ (Images) │   │  (Jobs)      │
└──────────┘   └──────┬───────┘
                      │
                      ▼
             ┌─────────────────┐
             │  ECS Fargate    │
             │  (Docker/YOLO)  │
             │  - SQS Worker   │
             └────────┬────────┘
                      │
                      ▼
             ┌─────────────────┐
             │  DynamoDB       │
             │  (Job Status)   │
             └─────────────────┘
```

**Benefits:**

- ✅ Cost-effective: ~\$0.15 per 100 images
- ✅ Scalable: Auto-scales based on queue depth
- ✅ Asynchronous: Non-blocking uploads
- ✅ Fault-tolerant: Automatic retries with SQS

## Tech Stack

### Frontend

- **Flutter** - Cross-platform mobile app (iOS/Android)

### Backend Services

- **AWS API Gateway** - REST API endpoints
- **AWS Lambda** - Serverless API handlers (Python 3.10)
- **Amazon S3** - Image storage
- **Amazon SQS** - Message queue for job processing
- **Amazon DynamoDB** - Job status tracking
- **AWS ECS Fargate** - Containerized ML processing
- **Amazon ECR** - Docker image registry

### ML & Processing

- **Ultralytics YOLOv11** - Object detection model
- **PyTorch** - Deep learning framework
- **OpenCV** - Image processing

## Implementation Steps

### Phase 1: AWS Infrastructure Setup

1. **AWS Account & IAM Setup**

   - Create AWS account
   - Set up IAM roles and policies
   - Configure AWS CLI

2. **S3 Bucket Configuration**

   - Create bucket for image uploads
   - Configure CORS policies
   - Set up lifecycle policies
   - Enable presigned URL generation

3. **API Gateway Setup**
   - Create REST API
   - Configure endpoints for:
     - Image upload (presigned URL generation)
     - Image processing job submission
     - Job status polling
   - Set up request/response models
   - Configure CORS

### Phase 2: Flutter Application Development

1. **Camera Module**

   - Integrate camera functionality
   - Implement image capture
   - Add image preview

2. **Image Upload Module**

   - Request presigned URLs from API Gateway
   - Upload to S3 using presigned URLs
   - Add progress indicators
   - Handle upload errors

3. **Processing Module**
   - Submit processing jobs via API
   - Poll job status
   - Display processing results

### Phase 3: Backend Processing (To be implemented)

1. **ML Processing Service**
   - Set up processing infrastructure
   - Integrate YOLOv11 model
   - Implement API endpoints for job processing

### Phase 4: Testing & Deployment

1. **Testing**
   - Integration tests for API Gateway
   - End-to-end testing
   - Mobile app testing

## Project Structure

```
AWS_TEST/
├── mobile-app/                 # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/            # API configuration
│   │   ├── screens/           # UI screens
│   │   │   ├── auth/         # Login/Signup
│   │   │   └── home/         # Camera, Home, Results
│   │   ├── services/          # API clients and services
│   │   ├── models/            # Data models
│   │   └── providers/         # State management
│   └── pubspec.yaml
├── backend-service/            # YOLOv11 Detection Service (Docker/ECS)
│   ├── app.py                 # FastAPI application
│   ├── Dockerfile             # Docker configuration
│   ├── requirements.txt       # Python dependencies
│   ├── build.ps1/.sh          # Build scripts
│   ├── deploy-to-ecr.ps1/.sh  # ECR deployment scripts
│   ├── task-definition.json   # ECS task definition
│   ├── README.md              # Service documentation
│   ├── DEPLOYMENT.md          # AWS ECS deployment guide
│   └── VEHICLE_DAMAGE_TRAINING.md  # Custom model training
└── README.md
```

## Prerequisites

### For AWS Deployment

- **AWS Account** (or AWS Academy Learner Lab)
- **Docker Desktop** - For building the YOLO container
- **AWS CLI** - For deployment commands
- **Git** - For cloning the repository

### For Flutter Development

- **Flutter SDK** (3.0+)
- **Android Studio** or **Xcode** (for iOS)
- **VS Code** or **Android Studio** (IDE)

## Getting Started

### Option 1: Deploy to AWS (Recommended First)

**Start here:** [QUICK_START_DEPLOYMENT.md](QUICK_START_DEPLOYMENT.md)

This guide walks you through:

1. Building the Docker image (can start immediately)
2. Deploying to AWS Learner Lab
3. Setting up all AWS infrastructure
4. Testing the complete system

**Estimated time:** 2 hours (first deployment)

### Option 2: Run Flutter App Locally (After AWS Deployment)

1. Ensure backend is deployed and you have the API Gateway URL
2. Navigate to `mobile-app/` directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Configure API endpoint in `lib/config/api_config.dart`:
   ```dart
   static const String apiBaseUrl = 'https://your-api-id.execute-api.us-east-1.amazonaws.com/prod';
   ```
5. Run the application:
   ```bash
   flutter run
   ```

## Cost Estimation

### Per 100 Image Processing Jobs

| Service                | Usage                          | Estimated Cost |
| ---------------------- | ------------------------------ | -------------- |
| **Lambda**             | 100 invocations, 512MB, 1s avg | ~\$0.0002      |
| **S3**                 | 300 operations, 1GB storage    | ~\$0.03        |
| **SQS**                | 200 messages                   | ~\$0.0001      |
| **DynamoDB**           | 200 writes, 100 reads          | ~\$0.0005      |
| **ECS Fargate**        | 1 task (2vCPU, 4GB) for 1 hour | ~\$0.12        |
| **Total per 100 jobs** |                                | **~\$0.15**    |

### Monthly Baseline Costs

| Service                    | Usage                    | Estimated Cost |
| -------------------------- | ------------------------ | -------------- |
| **ECR**                    | 2GB Docker image storage | ~\$0.20        |
| **CloudWatch Logs**        | 1GB logs                 | ~\$0.50        |
| **S3**                     | 5GB storage              | ~\$0.12        |
| **Total monthly baseline** |                          | **~\$0.82**    |

**AWS Learner Lab Credits:** Typically \$50-100, sufficient for extensive testing (10,000+ images)

**Scaling:** With auto-scaling, costs only increase when processing images. Idle time costs ~\$0.82/month.

## Security Considerations

- Implement proper IAM roles and policies
- Secure S3 bucket with presigned URLs
- Implement API Gateway authentication (API keys/JWT)
- Enable CORS properly
- Use HTTPS for all communications

## Current Status

✅ Flutter mobile app with camera functionality  
✅ Authentication UI ready  
✅ Image upload service configured for presigned URLs  
✅ Processing service ready for API Gateway integration  
✅ **Lambda Functions** for API Gateway (async architecture)  
✅ **SQS Worker** for ECS (processes images on-demand)  
✅ **Complete async architecture** (Lambda + SQS + ECS)  
✅ Deployment scripts for Lambda and ECS  
✅ Comprehensive documentation  
⏳ Deploy Lambda to API Gateway  
⏳ Deploy ECS worker  
⏳ Configure auto-scaling  
⏳ Train custom vehicle damage detection model

## Next Steps

### 1. Deploy Lambda Functions (API Layer)

```powershell
# Windows
cd backend-service\lambda
.\package-lambda.ps1
.\deploy-lambda.ps1 -Region "us-east-1" -FunctionName "image-processing-api"
```

See `backend-service/lambda/README.md` for detailed instructions.

### 2. Deploy ECS Worker (Processing Layer)

```powershell
# Windows - Build and deploy
cd backend-service
.\build.ps1
.\deploy-to-ecr.ps1 -Region "us-east-1" -AccountId "YOUR_AWS_ACCOUNT_ID"
```

Follow `backend-service/ASYNC_DEPLOYMENT.md` for complete setup.

### 3. Create AWS Resources

- S3 bucket with CORS
- SQS queue
- DynamoDB table
- API Gateway
- IAM roles

### 4. Mobile App Integration

- Update API Gateway URL in Flutter app
- Test end-to-end workflow

### 5. Custom Model Training (Optional)

- See `backend-service/VEHICLE_DAMAGE_TRAINING.md`
- Train YOLOv11 for vehicle damage detection
