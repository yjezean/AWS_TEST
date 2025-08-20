# Project Setup Guide

## Phase 1: AWS Infrastructure Setup

### Step 1: AWS Account & IAM Setup

1. **Create AWS Account**
   ```bash
   # Sign up at https://aws.amazon.com/
   # Enable MFA for root account
   # Create IAM user with programmatic access
   ```

2. **Configure AWS CLI**
   ```bash
   aws configure
   # Enter your Access Key ID
   # Enter your Secret Access Key
   # Enter your default region (e.g., us-east-1)
   ```

3. **Create IAM Roles**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:GetObject",
           "s3:PutObject",
           "s3:DeleteObject"
         ],
         "Resource": "arn:aws:s3:::your-bucket-name/*"
       },
       {
         "Effect": "Allow",
         "Action": [
           "lambda:InvokeFunction"
         ],
         "Resource": "arn:aws:lambda:*:*:function:image-processor"
       }
     ]
   }
   ```

### Step 2: S3 Bucket Configuration

1. **Create S3 Buckets**
   ```bash
   # Create bucket for uploaded images
   aws s3 mb s3://your-app-images-bucket
   
   # Create bucket for ML models
   aws s3 mb s3://your-ml-models-bucket
   ```

2. **Configure CORS for Images Bucket**
   ```json
   [
     {
       "AllowedHeaders": ["*"],
       "AllowedMethods": ["GET", "POST", "PUT"],
       "AllowedOrigins": ["*"],
       "ExposeHeaders": []
     }
   ]
   ```

3. **Set Bucket Policies**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "AllowCognitoAccess",
         "Effect": "Allow",
         "Principal": {
           "Federated": "cognito-identity.amazonaws.com"
         },
         "Action": [
           "s3:GetObject",
           "s3:PutObject"
         ],
         "Resource": "arn:aws:s3:::your-app-images-bucket/*"
       }
     ]
   }
   ```

### Step 3: AWS Cognito Setup

1. **Create User Pool**
   ```bash
   aws cognito-idp create-user-pool \
     --pool-name "MobileAppUserPool" \
     --policies "PasswordPolicy={MinimumLength=8,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=false}" \
     --auto-verified-attributes email
   ```

2. **Create User Pool Client**
   ```bash
   aws cognito-idp create-user-pool-client \
     --user-pool-id YOUR_USER_POOL_ID \
     --client-name "MobileAppClient" \
     --no-generate-secret \
     --explicit-auth-flows "ALLOW_USER_PASSWORD_AUTH" "ALLOW_REFRESH_TOKEN_AUTH"
   ```

3. **Create Identity Pool**
   ```bash
   aws cognito-identity create-identity-pool \
     --identity-pool-name "MobileAppIdentityPool" \
     --allow-unauthenticated-identities \
     --cognito-identity-providers ProviderName="cognito-idp.us-east-1.amazonaws.com/YOUR_USER_POOL_ID",ClientId="YOUR_CLIENT_ID",ServerSideTokenCheck=false
   ```

### Step 4: AppSync API Setup

1. **Install Amplify CLI**
   ```bash
   npm install -g @aws-amplify/cli
   amplify configure
   ```

2. **Initialize Amplify Project**
   ```bash
   amplify init
   # Choose your project name
   # Choose your environment
   # Choose your default editor
   # Choose JavaScript
   # Choose React
   # Choose AWS profile
   ```

3. **Add AppSync API**
   ```bash
   amplify add api
   # Choose GraphQL
   # Choose API key
   # Choose schema template: Single object with fields
   ```

4. **Define GraphQL Schema**
   ```graphql
   type Image @model @auth(rules: [{allow: owner}]) {
     id: ID!
     userId: String!
     imageUrl: String!
     status: String!
     results: String
     createdAt: AWSDateTime!
     updatedAt: AWSDateTime!
   }
   
   type Mutation {
     processImage(imageUrl: String!): Image
   }
   
   type Subscription {
     onImageProcessed(userId: String!): Image
     @aws_subscribe(mutations: ["processImage"])
   }
   ```

### Step 5: Lambda Function Setup

1. **Create Lambda Function**
   ```bash
   amplify add function
   # Choose Lambda function
   # Choose Node.js
   # Choose function name: imageProcessor
   ```

2. **Lambda Function Code**
   ```javascript
   const AWS = require('aws-sdk');
   const s3 = new AWS.S3();
   const pinpoint = new AWS.Pinpoint();
   
   exports.handler = async (event) => {
     try {
       const { imageUrl, userId } = JSON.parse(event.body);
       
       // Download image from S3
       const imageData = await s3.getObject({
         Bucket: 'your-app-images-bucket',
         Key: imageUrl
       }).promise();
       
       // Process with YOLOv11 (placeholder)
       const results = await processImageWithYOLO(imageData.Body);
       
       // Send notification via Pinpoint
       await sendNotification(userId, results);
       
       return {
         statusCode: 200,
         body: JSON.stringify({ results })
       };
     } catch (error) {
       return {
         statusCode: 500,
         body: JSON.stringify({ error: error.message })
       };
     }
   };
   ```

### Step 6: Amazon Pinpoint Setup

1. **Create Pinpoint Project**
   ```bash
   aws pinpoint create-app --name "MobileAppNotifications"
   ```

2. **Configure Push Notifications**
   ```bash
   # For iOS (APNs)
   aws pinpoint update-apns-channel \
     --application-id YOUR_PINPOINT_APP_ID \
     --certificate "path/to/certificate.pem" \
     --private-key "path/to/private-key.pem"
   
   # For Android (FCM)
   aws pinpoint update-gcm-channel \
     --application-id YOUR_PINPOINT_APP_ID \
     --api-key "YOUR_FCM_API_KEY"
   ```

## Phase 2: Flutter Application Development

### Step 1: Project Setup

1. **Create Flutter Project**
   ```bash
   flutter create mobile_app
   cd mobile_app
   ```

2. **Add Dependencies to pubspec.yaml**
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     amplify_flutter: ^0.6.0
     amplify_auth_cognito: ^0.6.0
     amplify_storage_s3: ^0.6.0
     amplify_api: ^0.6.0
     camera: ^0.10.5+5
     image_picker: ^1.0.4
     http: ^1.1.0
     provider: ^6.1.1
   ```

3. **Configure Amplify**
   ```bash
   amplify init
   amplify add auth
   amplify add storage
   amplify add api
   amplify push
   ```

### Step 2: Authentication Module

1. **Create Auth Service**
   ```dart
   // lib/services/auth_service.dart
   import 'package:amplify_flutter/amplify_flutter.dart';
   import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
   
   class AuthService {
     Future<AuthUser> signIn(String username, String password) async {
       try {
         final result = await Amplify.Auth.signIn(
           username: username,
           password: password,
         );
         return result.user;
       } catch (e) {
         throw Exception('Sign in failed: $e');
       }
     }
   
     Future<AuthUser> signUp(String username, String email, String password) async {
       try {
         final result = await Amplify.Auth.signUp(
           username: username,
           password: password,
           options: SignUpOptions(
             userAttributes: {
               AuthUserAttributeKey.email: email,
             },
           ),
         );
         return result.user;
       } catch (e) {
         throw Exception('Sign up failed: $e');
       }
     }
   }
   ```

### Step 3: Camera Module

1. **Create Camera Service**
   ```dart
   // lib/services/camera_service.dart
   import 'package:camera/camera.dart';
   import 'package:image_picker/image_picker.dart';
   
   class CameraService {
     CameraController? _controller;
     List<CameraDescription>? _cameras;
   
     Future<void> initialize() async {
       _cameras = await availableCameras();
       if (_cameras!.isNotEmpty) {
         _controller = CameraController(_cameras![0], ResolutionPreset.high);
         await _controller!.initialize();
       }
     }
   
     Future<XFile?> captureImage() async {
       if (_controller?.value.isInitialized ?? false) {
         return await _controller!.takePicture();
       }
       return null;
     }
   }
   ```

### Step 4: Image Upload Module

1. **Create Upload Service**
   ```dart
   // lib/services/upload_service.dart
   import 'package:amplify_storage_s3/amplify_storage_s3.dart';
   import 'dart:io';
   
   class UploadService {
     Future<String> uploadImage(File imageFile) async {
       try {
         final key = 'images/${DateTime.now().millisecondsSinceEpoch}.jpg';
         final result = await Amplify.Storage.uploadFile(
           local: imageFile,
           key: key,
           options: StorageUploadFileOptions(
             accessLevel: StorageAccessLevel.private,
           ),
         ).result;
         return result.key;
       } catch (e) {
         throw Exception('Upload failed: $e');
       }
     }
   }
   ```

## Phase 3: ML Model Integration

### Step 1: YOLOv11 Model Setup

1. **Download YOLOv11 Model**
   ```bash
   # Download pre-trained YOLOv11 model
   wget https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov11n.pt
   ```

2. **Optimize Model for Lambda**
   ```python
   import torch
   from ultralytics import YOLO
   
   # Load model
   model = YOLO('yolov11n.pt')
   
   # Export to ONNX for better Lambda compatibility
   model.export(format='onnx', dynamic=True)
   ```

### Step 2: Lambda Function with YOLOv11

1. **Enhanced Lambda Function**
   ```python
   import json
   import boto3
   import numpy as np
   import cv2
   from ultralytics import YOLO
   import io
   from PIL import Image
   
   def lambda_handler(event, context):
       try:
           # Parse input
           body = json.loads(event['body'])
           image_url = body['imageUrl']
           user_id = body['userId']
           
           # Download image from S3
           s3 = boto3.client('s3')
           bucket_name = 'your-app-images-bucket'
           response = s3.get_object(Bucket=bucket_name, Key=image_url)
           image_data = response['Body'].read()
           
           # Load and preprocess image
           image = Image.open(io.BytesIO(image_data))
           image_np = np.array(image)
           
           # Load YOLOv11 model
           model = YOLO('/opt/yolov11n.pt')
           
           # Run inference
           results = model(image_np)
           
           # Process results
           detections = []
           for result in results:
               boxes = result.boxes
               if boxes is not None:
                   for box in boxes:
                       detection = {
                           'class': int(box.cls[0]),
                           'confidence': float(box.conf[0]),
                           'bbox': box.xyxy[0].tolist()
                       }
                       detections.append(detection)
           
           # Send notification via Pinpoint
           pinpoint = boto3.client('pinpoint')
           pinpoint.send_messages(
               ApplicationId='YOUR_PINPOINT_APP_ID',
               MessageRequest={
                   'Addresses': {
                       user_id: {
                           'ChannelType': 'PUSH'
                       }
                   },
                   'MessageConfiguration': {
                       'DefaultPushNotificationMessage': {
                           'Title': 'Image Analysis Complete',
                           'Body': f'Found {len(detections)} objects in your image',
                           'Data': json.dumps(detections)
                       }
                   }
               }
           )
           
           return {
               'statusCode': 200,
               'body': json.dumps({
                   'detections': detections,
                   'message': 'Analysis complete'
               })
           }
           
       except Exception as e:
           return {
               'statusCode': 500,
               'body': json.dumps({'error': str(e)})
           }
   ```

## Phase 4: Testing & Deployment

### Step 1: Local Testing

1. **Test Flutter App**
   ```bash
   cd mobile_app
   flutter test
   flutter run
   ```

2. **Test Lambda Function**
   ```bash
   # Create test event
   echo '{"body": "{\"imageUrl\": \"test-image.jpg\", \"userId\": \"test-user\"}"}' > test-event.json
   
   # Test locally
   aws lambda invoke \
     --function-name imageProcessor \
     --payload file://test-event.json \
     response.json
   ```

### Step 2: Amplify Deployment

1. **Deploy Backend**
   ```bash
   amplify push
   ```

2. **Deploy Frontend**
   ```bash
   amplify publish
   ```

## Next Steps

1. **Start with Phase 1**: Set up AWS infrastructure
2. **Move to Phase 2**: Develop Flutter application
3. **Implement Phase 3**: Integrate ML model
4. **Complete Phase 4**: Test and deploy

## Troubleshooting

### Common Issues:
1. **Lambda Timeout**: Increase timeout for ML processing
2. **Memory Issues**: Increase Lambda memory allocation
3. **CORS Errors**: Verify S3 bucket CORS configuration
4. **Authentication Errors**: Check Cognito configuration

### Performance Optimization:
1. **Model Optimization**: Use TensorRT or ONNX for faster inference
2. **Image Compression**: Compress images before upload
3. **Caching**: Implement result caching
4. **CDN**: Use CloudFront for image delivery
