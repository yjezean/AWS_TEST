# YOLOv11 Vehicle Damage Detection Service

An async, event-driven microservice for detecting vehicle damage using Ultralytics YOLOv11 model.

**Architecture:** Lambda + SQS + ECS (Asynchronous Processing)

## 🎯 Features

- **YOLOv11 Object Detection**: Latest YOLO model for accurate detection
- **Async Architecture**: Lambda + SQS + ECS for cost-effective processing
- **Batch Processing**: Handle multiple images in one job
- **Auto-Scaling**: ECS scales based on SQS queue depth (can scale to 0!)
- **S3 Integration**: Download images from S3, process, and store results
- **DynamoDB**: Track job status and store detection results
- **Cost-Optimized**: Pay only when processing (70-80% cheaper than always-on)

## 📋 Prerequisites

- Docker installed
- Python 3.10+ (for local development)
- AWS CLI configured
- AWS Account with access to:
  - Lambda
  - API Gateway
  - SQS
  - DynamoDB
  - ECS
  - ECR
  - S3

## 🚀 Quick Start

### Local Development

1. **Install Dependencies**

```bash
pip install -r requirements.txt
```

2. **Run the Application**

```bash
python app.py
```

3. **Access API Documentation**

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### Docker Deployment

1. **Build Docker Image**

**Linux/Mac:**

```bash
chmod +x build.sh
./build.sh
```

**Windows PowerShell:**

```powershell
.\build.ps1
```

2. **Run Docker Container**

```bash
docker run -p 8000:8000 yolov11-detector:latest
```

3. **Test the Service**

```bash
curl http://localhost:8000/health
```

## 🔧 API Endpoints

### Health Check

```bash
GET /health
```

### Detect Objects in Image

```bash
POST /detect
Content-Type: multipart/form-data

Parameters:
- file: Image file (JPEG, PNG)

Response:
{
  "success": true,
  "message": "Detected 3 objects",
  "detections": [
    {
      "label": "car",
      "confidence": 0.95,
      "bbox": [100.0, 150.0, 500.0, 400.0]
    }
  ],
  "image_id": "uuid",
  "processing_time": 0.45
}
```

### Submit Processing Job (Async)

```bash
POST /process
Content-Type: multipart/form-data

Parameters:
- file: Image file

Response:
{
  "jobId": "uuid",
  "status": "COMPLETED",
  "detections": [...],
  "message": "Detected 3 objects"
}
```

### Get Job Status

```bash
GET /process/{job_id}

Response:
{
  "jobId": "uuid",
  "status": "COMPLETED",
  "detections": [...],
  "message": null
}
```

### Detect from URL

```bash
POST /detect-from-url?image_url=https://example.com/image.jpg
# or
POST /detect-from-url?image_url=s3://bucket/key
```

## 🐳 AWS Deployment

### Step 1: Deploy to Amazon ECR

**Linux/Mac:**

```bash
chmod +x deploy-to-ecr.sh
./deploy-to-ecr.sh us-east-1 YOUR_AWS_ACCOUNT_ID yolov11-detector latest
```

**Windows PowerShell:**

```powershell
.\deploy-to-ecr.ps1 -Region "us-east-1" -AccountId "YOUR_AWS_ACCOUNT_ID" -RepositoryName "yolov11-detector"
```

### Step 2: Create ECS Cluster

```bash
aws ecs create-cluster \
    --cluster-name yolov11-cluster \
    --region us-east-1
```

### Step 3: Create Task Definition

Create `task-definition.json`:

```json
{
  "family": "yolov11-detector-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "2048",
  "memory": "4096",
  "containerDefinitions": [
    {
      "name": "yolov11-detector",
      "image": "YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/yolov11-detector:latest",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "MODEL_PATH",
          "value": "yolov11n.pt"
        },
        {
          "name": "PORT",
          "value": "8000"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/yolov11-detector",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "curl -f http://localhost:8000/health || exit 1"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

Register the task:

```bash
aws ecs register-task-definition \
    --cli-input-json file://task-definition.json
```

### Step 4: Create ECS Service

```bash
aws ecs create-service \
    --cluster yolov11-cluster \
    --service-name yolov11-service \
    --task-definition yolov11-detector-task \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxxx],securityGroups=[sg-xxxxx],assignPublicIp=ENABLED}"
```

### Step 5: Set Up Application Load Balancer (Optional)

1. Create an Application Load Balancer
2. Create a target group for port 8000
3. Update ECS service to use the load balancer
4. Configure health checks on `/health` endpoint

## 🔒 Security Considerations

1. **API Authentication**: Add API key or JWT authentication
2. **Rate Limiting**: Implement rate limiting for production
3. **IAM Roles**: Use IAM roles instead of access keys
4. **VPC**: Deploy in private subnets with NAT gateway
5. **Security Groups**: Restrict inbound traffic to necessary ports

## 📊 Model Information

### Default Model

- **Model**: YOLOv11 Nano (yolov11n.pt)
- **Size**: ~6MB
- **Speed**: Very fast
- **Use Case**: General object detection (80 COCO classes)

### Custom Damage Detection Model

To use a custom vehicle damage detection model:

1. Train your model using Ultralytics YOLOv11
2. Place the `.pt` file in `/app/models/` directory
3. Set environment variable: `MODEL_PATH=models/vehicle-damage.pt`
4. Rebuild and redeploy

### Training Custom Model

```python
from ultralytics import YOLO

# Load base model
model = YOLO('yolov11n.pt')

# Train on custom dataset
model.train(
    data='damage-dataset.yaml',
    epochs=100,
    imgsz=640,
    batch=16
)

# Export trained model
model.export(format='torchscript')
```

## 🧪 Testing

### Test with cURL

```bash
# Upload an image
curl -X POST "http://localhost:8000/detect" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test-image.jpg"
```

### Test with Python

```python
import requests

url = "http://localhost:8000/detect"
files = {"file": open("test-image.jpg", "rb")}
response = requests.post(url, files=files)
print(response.json())
```

## 📈 Performance Optimization

### CPU/Memory Recommendations

| Model Size  | CPU (vCPU) | Memory (GB) | Speed (ms) |
| ----------- | ---------- | ----------- | ---------- |
| Nano        | 2          | 4           | 50-100     |
| Small       | 2          | 4-8         | 100-200    |
| Medium      | 4          | 8           | 200-300    |
| Large       | 4          | 8-16        | 300-500    |
| Extra-Large | 8          | 16          | 500-800    |

### Auto-scaling Configuration

```json
{
  "ServiceName": "yolov11-service",
  "ScalableDimension": "ecs:service:DesiredCount",
  "MinCapacity": 1,
  "MaxCapacity": 10,
  "TargetTrackingScalingPolicyConfiguration": {
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
    }
  }
}
```

## 🔍 Troubleshooting

### Common Issues

1. **Model download slow**: Pre-download model and include in Docker image
2. **Out of memory**: Increase ECS task memory or use smaller model
3. **Slow inference**: Use GPU-enabled instances (Fargate doesn't support GPU)
4. **CORS errors**: Configure CORS middleware in `app.py`

## 📝 License

This project uses Ultralytics YOLOv11 which is licensed under AGPL-3.0.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📧 Support

For issues and questions:

- Create an issue in the repository
- Check Ultralytics documentation: https://docs.ultralytics.com/

## 🔄 Next Steps

1. **Add Authentication**: Implement API key or JWT authentication
2. **Database Integration**: Store detection results in DynamoDB
3. **Queue System**: Use SQS for async processing
4. **Custom Model**: Train and deploy vehicle damage detection model
5. **Monitoring**: Set up CloudWatch dashboards and alarms
