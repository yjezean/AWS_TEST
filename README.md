# AWS Mobile Application with ML Image Detection

## Project Overview

A Flutter mobile application that captures images, uploads them to AWS, and processes them through YOLOv11 for object detection using AWS API Gateway.

## Architecture

```
┌─────────────────┐
│   Flutter App   │
│                 │
└─────────────────┘
         │
         ▼
┌─────────────────┐    ┌─────────────┐
│  API Gateway    │───▶│  S3 Bucket  │
│  (REST API)     │    │ (Images)    │
└─────────────────┘    └─────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  ML Processing Backend          │
│  (To be implemented)            │
└─────────────────────────────────┘
```

## Tech Stack

- **Frontend**: Flutter (Mobile App)
- **Backend**: AWS API Gateway (REST API)
- **Storage**: Amazon S3
- **ML Model**: YOLOv11 (Object Detection) - To be integrated

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
aws-mobile-app/
├── mobile-app/                 # Flutter application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/            # API configuration
│   │   ├── screens/           # UI screens
│   │   │   ├── auth/         # Login/Signup
│   │   │   └── home/         # Camera, Home, Results
│   │   ├── services/          # API clients and services
│   │   ├── models/            # Data models
│   │   └── providers/         # State management
│   ├── pubspec.yaml
│   └── android/
└── README.md
```

## Prerequisites

- AWS Account with API Gateway and S3 access
- Flutter SDK (3.0+)
- AWS CLI configured
- Android Studio / Xcode

## Getting Started

1. Clone this repository
2. Navigate to `mobile-app/` directory
3. Run `flutter pub get` to install dependencies
4. Configure API Gateway endpoint in `lib/config/api_config.dart`
5. Run the application: `flutter run`

## Cost Estimation

- **S3**: ~\$0.023 per GB storage
- **API Gateway**: ~\$1.00 per million requests
- **Data Transfer**: Varies by region

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
⏳ API Gateway configuration needed
⏳ Backend ML processing to be implemented

## Next Steps

1. Set up AWS API Gateway with required endpoints
2. Configure S3 bucket with CORS
3. Test presigned URL generation
4. Implement backend processing service
5. Integrate YOLOv11 for object detection
