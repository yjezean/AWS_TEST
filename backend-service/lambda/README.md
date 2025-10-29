# Lambda Functions for Image Processing API

This directory contains Lambda functions for the async image processing architecture.

## 📋 Overview

Lambda functions handle:

- **API Gateway endpoints** (presigned URLs, job submission, status checks)
- **Request validation** and authentication
- **Job creation** in DynamoDB
- **Message queuing** to SQS

The actual image processing happens in **ECS workers** (not Lambda).

---

## 🏗️ Architecture

```
API Gateway → Lambda → SQS → ECS Worker
                ↓              ↓
            DynamoDB      Process Images
```

---

## 📦 Files

- **`lambda_handler.py`** - Main Lambda handlers

  - `lambda_handler()` - Submit processing job
  - `get_job_status_handler()` - Get job status
  - `generate_presigned_url_handler()` - Generate S3 upload URL

- **`package-lambda.sh/.ps1`** - Package Lambda for deployment
- **`deploy-lambda.sh/.ps1`** - Deploy to AWS

---

## 🚀 Deployment

### Step 1: Package Lambda

**Windows:**

```powershell
cd lambda
.\package-lambda.ps1
```

**Linux/Mac:**

```bash
cd lambda
chmod +x package-lambda.sh
./package-lambda.sh
```

This creates `lambda-deployment.zip`.

### Step 2: Create Required AWS Resources

#### Create IAM Role for Lambda

```bash
# Create trust policy
cat > lambda-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "lambda.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
EOF

# Create role
aws iam create-role \
  --role-name lambda-execution-role \
  --assume-role-policy-document file://lambda-trust-policy.json

# Attach policies
aws iam attach-role-policy \
  --role-name lambda-execution-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Attach custom policy for S3, SQS, DynamoDB
cat > lambda-permissions.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::image-processing-uploads/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "arn:aws:sqs:*:*:image-processing-queue"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/image-processing-jobs"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name lambda-execution-role \
  --policy-name lambda-custom-permissions \
  --policy-document file://lambda-permissions.json
```

#### Create S3 Bucket

```bash
aws s3 mb s3://image-processing-uploads --region us-east-1

# Enable CORS
cat > cors.json <<EOF
{
  "CORSRules": [{
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["PUT", "POST", "GET"],
    "AllowedHeaders": ["*"],
    "MaxAgeSeconds": 3000
  }]
}
EOF

aws s3api put-bucket-cors \
  --bucket image-processing-uploads \
  --cors-configuration file://cors.json
```

#### Create SQS Queue

```bash
aws sqs create-queue \
  --queue-name image-processing-queue \
  --region us-east-1
```

#### Create DynamoDB Table

```bash
aws dynamodb create-table \
  --table-name image-processing-jobs \
  --attribute-definitions \
    AttributeName=jobId,AttributeType=S \
  --key-schema \
    AttributeName=jobId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### Step 3: Deploy Lambda Function

**Windows:**

```powershell
.\deploy-lambda.ps1 -Region "us-east-1" -FunctionName "image-processing-api"
```

**Linux/Mac:**

```bash
./deploy-lambda.sh us-east-1 image-processing-api
```

### Step 4: Create API Gateway

```bash
# Create REST API
API_ID=$(aws apigateway create-rest-api \
  --name "Image Processing API" \
  --region us-east-1 \
  --query 'id' \
  --output text)

# Get root resource ID
ROOT_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --region us-east-1 \
  --query 'items[0].id' \
  --output text)

# Create /uploads resource
UPLOADS_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_ID \
  --path-part uploads \
  --region us-east-1 \
  --query 'id' \
  --output text)

# Create /uploads/presign resource
PRESIGN_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $UPLOADS_ID \
  --path-part presign \
  --region us-east-1 \
  --query 'id' \
  --output text)

# Create POST method
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $PRESIGN_ID \
  --http-method POST \
  --authorization-type NONE \
  --region us-east-1

# Get Lambda ARN
LAMBDA_ARN=$(aws lambda get-function \
  --function-name image-processing-api \
  --region us-east-1 \
  --query 'Configuration.FunctionArn' \
  --output text)

# Create Lambda integration
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $PRESIGN_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations \
  --region us-east-1

# Grant API Gateway permission to invoke Lambda
aws lambda add-permission \
  --function-name image-processing-api \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:*:${API_ID}/*" \
  --region us-east-1

# Deploy API
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --region us-east-1

echo "API Gateway URL: https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod"
```

---

## 📝 API Endpoints

### 1. Generate Presigned URL

**Endpoint:** `POST /uploads/presign`

**Request:**

```json
{
  "filename": "car-damage.jpg",
  "contentType": "image/jpeg"
}
```

**Response:**

```json
{
  "url": "https://s3.amazonaws.com/...",
  "key": "uploads/2024/01/15/uuid-car-damage.jpg",
  "bucket": "image-processing-uploads"
}
```

### 2. Submit Processing Job

**Endpoint:** `POST /process`

**Request:**

```json
{
  "imageUrls": [
    "s3://image-processing-uploads/uploads/2024/01/15/uuid-image1.jpg",
    "s3://image-processing-uploads/uploads/2024/01/15/uuid-image2.jpg"
  ],
  "userId": "user123",
  "metadata": {
    "source": "mobile-app",
    "version": "1.0"
  }
}
```

**Response:**

```json
{
  "success": true,
  "jobId": "uuid-job-id",
  "status": "PENDING",
  "message": "Job created for 2 image(s)",
  "imageCount": 2
}
```

### 3. Get Job Status

**Endpoint:** `GET /jobs/{jobId}`

**Response (Pending):**

```json
{
  "jobId": "uuid-job-id",
  "status": "PENDING",
  "imageCount": 2,
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

**Response (Completed):**

```json
{
  "jobId": "uuid-job-id",
  "status": "COMPLETED",
  "imageCount": 2,
  "detections": [
    {
      "imageUrl": "s3://...",
      "imageIndex": 0,
      "detections": [
        {
          "label": "car",
          "confidence": 0.95,
          "bbox": [100, 150, 500, 400]
        }
      ],
      "detectionCount": 1
    }
  ],
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:31:23Z"
}
```

---

## 🧪 Testing

### Test Locally

```bash
# Install dependencies
pip install boto3 python-dotenv

# Set environment variables
export SQS_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/123456789012/image-processing-queue
export JOBS_TABLE_NAME=image-processing-jobs
export S3_BUCKET=image-processing-uploads

# Test presigned URL generation
python -c "
from lambda_handler import generate_presigned_url_handler
event = {
    'body': '{\"filename\": \"test.jpg\", \"contentType\": \"image/jpeg\"}'
}
result = generate_presigned_url_handler(event, None)
print(result)
"
```

### Test in AWS

```bash
# Invoke Lambda directly
aws lambda invoke \
  --function-name image-processing-api \
  --payload '{"body": "{\"filename\": \"test.jpg\"}"}' \
  --region us-east-1 \
  output.json

cat output.json
```

---

## 📊 Monitoring

### CloudWatch Logs

```bash
# View logs
aws logs tail /aws/lambda/image-processing-api --follow
```

### Metrics

```bash
# Get invocation count
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=image-processing-api \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

---

## 💰 Cost Estimation

**Lambda (1000 requests/day):**

- Compute: ~\$0.20/month
- Requests: ~\$0.06/month

**S3:**

- Storage: ~\$0.023/GB
- Requests: ~\$0.005/1000 PUT

**SQS:**

- Free tier: 1M requests/month
- After: \$0.40/million

**DynamoDB:**

- On-demand: $1.25/million writes, $0.25/million reads

**Total: ~\$0.50-2.00/month for 1000 requests/day**

---

## 🔒 Security Best Practices

1. **Enable API Gateway authentication** (API Keys or Cognito)
2. **Restrict S3 bucket** access with IAM policies
3. **Encrypt data** at rest (S3, DynamoDB)
4. **Use VPC endpoints** for Lambda to reduce costs
5. **Implement rate limiting** on API Gateway
6. **Enable CloudTrail** for audit logging

---

## 🔧 Troubleshooting

### Lambda timeout

- Increase timeout in Lambda configuration (default: 3s, max: 900s)
- Lambda should NOT process images (ECS does that)

### Permission errors

- Check IAM role has correct policies
- Verify resource ARNs are correct

### SQS messages not processing

- Check ECS worker is running
- Verify SQS queue URL is correct
- Check DLQ for failed messages

---

## 📚 Next Steps

1. Deploy Lambda functions
2. Set up API Gateway
3. Deploy ECS worker (see parent directory)
4. Test end-to-end workflow
5. Configure monitoring and alerts
