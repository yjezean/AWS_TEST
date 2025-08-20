# Getting Started Guide

## 🚀 Quick Start

This guide will walk you through setting up and running the AWS Mobile Application with ML Image Detection.

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### Required Software
- **AWS Account** - [Sign up here](https://aws.amazon.com/)
- **AWS CLI** - [Install guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Flutter SDK** (3.0+) - [Install guide](https://docs.flutter.dev/get-started/install)
- **Node.js** (16+) - [Download here](https://nodejs.org/)
- **Amplify CLI** - Install with `npm install -g @aws-amplify/cli`
- **Git** - [Download here](https://git-scm.com/)

### Development Tools
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **VS Code** (recommended editor)

## 🛠️ Installation Steps

### Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd AWS_TEST
```

### Step 2: Configure AWS Credentials

```bash
aws configure
```

Enter your AWS Access Key ID, Secret Access Key, default region (e.g., `us-east-1`), and output format (`json`).

### Step 3: Install Dependencies

```bash
# Install Amplify CLI globally
npm install -g @aws-amplify/cli

# Configure Amplify
amplify configure
```

### Step 4: Set Up Flutter Project

```bash
cd mobile-app

# Get Flutter dependencies
flutter pub get

# Verify Flutter installation
flutter doctor
```

## 🏗️ AWS Infrastructure Setup

### Option A: Automated Deployment (Recommended)

Run the deployment script:

```bash
# Make script executable
chmod +x deployment-scripts/deploy.sh

# Run deployment
./deployment-scripts/deploy.sh
```

### Option B: Manual Setup

Follow the detailed setup guide in `project-setup.md` for step-by-step manual configuration.

## 📱 Flutter App Setup

### Step 1: Configure Amplify

```bash
cd mobile-app

# Initialize Amplify project
amplify init

# Add authentication
amplify add auth

# Add storage
amplify add storage

# Add API
amplify add api

# Push changes
amplify push
```

### Step 2: Update Configuration

After running `amplify push`, update your `lib/main.dart` file with the generated configuration:

```dart
// Replace the placeholder configuration in main.dart
await Amplify.configure(amplifyconfig);
```

### Step 3: Run the App

```bash
# For web
flutter run -d chrome

# For Android
flutter run -d android

# For iOS
flutter run -d ios
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
AWS_REGION=us-east-1
IMAGES_BUCKET=your-app-images-bucket
MODELS_BUCKET=your-ml-models-bucket
PINPOINT_APP_ID=your-pinpoint-app-id
```

### AWS Services Configuration

#### S3 Buckets
- **Images Bucket**: Stores uploaded images
- **Models Bucket**: Stores YOLOv11 model files

#### Cognito User Pool
- Configured for email/password authentication
- Auto-confirmation enabled for development

#### AppSync API
- GraphQL API for real-time updates
- Subscriptions for processing status

#### Lambda Function
- Processes images with YOLOv11
- Sends notifications via Pinpoint

#### Amazon Pinpoint
- Handles push notifications
- Configured for both iOS and Android

## 🧪 Testing

### Test Authentication

1. Run the app
2. Create a new account
3. Sign in with credentials
4. Verify authentication flow

### Test Camera Functionality

1. Navigate to home screen
2. Tap "Capture Image"
3. Take a photo
4. Verify upload to S3

### Test Image Processing

1. Capture an image
2. Wait for processing
3. Check results screen
4. Verify notifications

## 🔍 Troubleshooting

### Common Issues

#### AWS CLI Configuration
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Reconfigure if needed
aws configure
```

#### Flutter Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### Amplify Issues
```bash
# Reset Amplify
amplify init --app
amplify push
```

#### Camera Permissions
- **Android**: Add permissions to `android/app/src/main/AndroidManifest.xml`
- **iOS**: Add permissions to `ios/Runner/Info.plist`

### Error Solutions

#### "Camera not available"
- Check device permissions
- Verify camera hardware
- Test on physical device

#### "Upload failed"
- Check S3 bucket permissions
- Verify Cognito configuration
- Check network connectivity

#### "Processing failed"
- Check Lambda function logs
- Verify YOLOv11 model deployment
- Check AppSync configuration

## 📊 Monitoring

### CloudWatch Logs
- Lambda function logs
- AppSync API logs
- Application logs

### AWS X-Ray
- Trace requests through services
- Monitor performance
- Debug issues

### Cost Monitoring
- Set up billing alerts
- Monitor service usage
- Optimize costs

## 🔒 Security

### Best Practices
- Use IAM roles with minimal permissions
- Enable MFA for AWS accounts
- Encrypt data at rest and in transit
- Regular security audits

### Compliance
- GDPR compliance for user data
- HIPAA compliance if applicable
- SOC 2 compliance for enterprise

## 📈 Scaling

### Performance Optimization
- Use CloudFront for image delivery
- Implement caching strategies
- Optimize Lambda function
- Use auto-scaling groups

### Cost Optimization
- Use S3 lifecycle policies
- Implement Lambda concurrency limits
- Monitor and optimize usage
- Use reserved instances where applicable

## 🚀 Deployment

### Production Deployment

1. **Environment Setup**
   ```bash
   amplify env add prod
   amplify env checkout prod
   ```

2. **Security Hardening**
   - Enable MFA
   - Configure WAF
   - Set up monitoring

3. **Performance Tuning**
   - Optimize Lambda functions
   - Configure auto-scaling
   - Set up CDN

4. **Testing**
   - Load testing
   - Security testing
   - User acceptance testing

### CI/CD Pipeline

Set up automated deployment:

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
      - uses: subosito/flutter-action@v2
      - run: |
          cd mobile-app
          flutter build web
          amplify publish --yes
```

## 📚 Additional Resources

### Documentation
- [AWS Amplify Documentation](https://docs.amplify.aws/)
- [Flutter Documentation](https://docs.flutter.dev/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [YOLOv11 Documentation](https://github.com/ultralytics/ultralytics)

### Tutorials
- [AWS Amplify Flutter Tutorial](https://docs.amplify.aws/start/getting-started/integrate/q/integration/flutter/)
- [Flutter Camera Tutorial](https://docs.flutter.dev/cookbook/plugins/picture-using-camera)
- [AWS Lambda Tutorial](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)

### Support
- [AWS Support](https://aws.amazon.com/support/)
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you encounter any issues:

1. Check the troubleshooting section
2. Search existing issues
3. Create a new issue with details
4. Contact the development team

---

**Happy Coding! 🎉**
