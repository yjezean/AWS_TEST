"""
ECS Worker that processes images from SQS queue
Downloads images from S3 and runs YOLO detection
"""

import json
import boto3
import os
import time
import logging
from datetime import datetime
from ultralytics import YOLO
import cv2
import numpy as np
from io import BytesIO
from decimal import Decimal

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# AWS clients
s3_client = boto3.client('s3')
sqs_client = boto3.client('sqs')
dynamodb = boto3.resource('dynamodb')

# Configuration
SQS_QUEUE_URL = os.environ.get('SQS_QUEUE_URL')
JOBS_TABLE_NAME = os.environ.get('JOBS_TABLE_NAME', 'image-processing-jobs')
MODEL_PATH = os.environ.get('MODEL_PATH', 'yolov11n.pt')
RESULTS_BUCKET = os.environ.get('RESULTS_BUCKET')

# Load YOLO model
logger.info(f"Loading YOLO model: {MODEL_PATH}")
model = YOLO(MODEL_PATH)
logger.info("Model loaded successfully")


def download_image_from_s3(s3_url):
    """
    Download image from S3 URL
    
    Args:
        s3_url: s3://bucket/key or https://bucket.s3.region.amazonaws.com/key
    
    Returns:
        numpy array of image
    """
    try:
        # Parse S3 URL
        if s3_url.startswith('s3://'):
            # s3://bucket/key
            parts = s3_url.replace('s3://', '').split('/', 1)
            bucket = parts[0]
            key = parts[1]
        elif 's3.amazonaws.com' in s3_url or 's3.' in s3_url:
            # https://bucket.s3.region.amazonaws.com/key
            # Parse URL
            from urllib.parse import urlparse
            parsed = urlparse(s3_url)
            bucket = parsed.hostname.split('.')[0]
            key = parsed.path.lstrip('/')
        else:
            raise ValueError(f"Invalid S3 URL format: {s3_url}")
        
        logger.info(f"Downloading from S3: bucket={bucket}, key={key}")
        
        # Download from S3
        response = s3_client.get_object(Bucket=bucket, Key=key)
        image_data = response['Body'].read()
        
        # Convert to numpy array
        nparr = np.frombuffer(image_data, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        return img, bucket, key
        
    except Exception as e:
        logger.error(f"Error downloading image: {e}")
        raise


def process_image(img):
    """
    Process image with YOLO model
    
    Args:
        img: numpy array of image
    
    Returns:
        list of detections
    """
    try:
        # Run inference
        results = model(img)
        
        # Parse detections
        detections = []
        for result in results:
            boxes = result.boxes
            for box in boxes:
                # Get box coordinates
                x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                
                # Get confidence and class
                conf = float(box.conf[0].cpu().numpy())
                cls = int(box.cls[0].cpu().numpy())
                
                # Get class name
                class_name = model.names[cls]
                
                detections.append({
                    'label': class_name,
                    'confidence': conf,
                    'bbox': [float(x1), float(y1), float(x2), float(y2)]
                })
        
        logger.info(f"Found {len(detections)} objects")
        return detections
        
    except Exception as e:
        logger.error(f"Error processing image: {e}")
        raise


def _to_decimal(value):
    """Recursively convert floats in nested dict/list structures to Decimal for DynamoDB."""
    if isinstance(value, float):
        return Decimal(str(value))
    if isinstance(value, list):
        return [_to_decimal(v) for v in value]
    if isinstance(value, dict):
        return {k: _to_decimal(v) for k, v in value.items()}
    return value

def update_job_status(job_id, status, detections=None, message=None):
    """Update job status in DynamoDB"""
    try:
        jobs_table = dynamodb.Table(JOBS_TABLE_NAME)
        
        update_expression = "SET #status = :status, updatedAt = :updated"
        expression_values = {
            ':status': status,
            ':updated': datetime.utcnow().isoformat()
        }
        expression_names = {
            '#status': 'status'
        }
        
        if detections is not None:
            update_expression += ", detections = :detections"
            # Convert any float values to Decimal for DynamoDB compatibility
            expression_values[':detections'] = _to_decimal(detections)
        
        if message is not None:
            update_expression += ", message = :message"
            expression_values[':message'] = message
        
        jobs_table.update_item(
            Key={'jobId': job_id},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_names,
            ExpressionAttributeValues=expression_values
        )
        
        logger.info(f"Updated job {job_id} to status {status}")
        
    except Exception as e:
        logger.error(f"Error updating job status: {e}")
        raise


def process_sqs_message(message):
    """
    Process a single SQS message
    
    Args:
        message: SQS message dict
    """
    try:
        # Parse message body
        body = json.loads(message['Body'])
        job_id = body['jobId']
        image_urls = body['imageUrls']
        user_id = body.get('userId')
        
        logger.info(f"Processing job {job_id} with {len(image_urls)} image(s)")
        
        # Update status to RUNNING
        update_job_status(job_id, 'RUNNING')
        
        # Process each image
        all_detections = []
        
        for idx, image_url in enumerate(image_urls):
            logger.info(f"Processing image {idx + 1}/{len(image_urls)}: {image_url}")
            
            try:
                # Download image
                img, bucket, key = download_image_from_s3(image_url)
                
                # Process with YOLO
                detections = process_image(img)
                
                # Add image info to detections
                image_result = {
                    'imageUrl': image_url,
                    'imageIndex': idx,
                    'detections': detections,
                    'detectionCount': len(detections)
                }
                
                all_detections.append(image_result)
                
            except Exception as e:
                logger.error(f"Error processing image {image_url}: {e}")
                all_detections.append({
                    'imageUrl': image_url,
                    'imageIndex': idx,
                    'error': str(e),
                    'detections': []
                })
        
        # Update job with results
        logger.info(f"About to update job {job_id} with {len(all_detections)} detection results")
        logger.info(f"Detection data: {all_detections}")
        update_job_status(
            job_id,
            'COMPLETED',
            detections=all_detections,
            message=f"Processed {len(image_urls)} images successfully"
        )
        
        # Delete message from queue
        sqs_client.delete_message(
            QueueUrl=SQS_QUEUE_URL,
            ReceiptHandle=message['ReceiptHandle']
        )
        
        logger.info(f"Job {job_id} completed successfully")
        
    except Exception as e:
        logger.error(f"Error processing message: {e}")
        
        # Update job status to FAILED
        try:
            update_job_status(
                job_id,
                'FAILED',
                message=str(e)
            )
        except:
            pass
        
        raise


def main():
    """Main worker loop - polls SQS and processes messages"""
    logger.info("Starting SQS worker...")
    logger.info(f"Queue URL: {SQS_QUEUE_URL}")
    logger.info(f"Jobs Table: {JOBS_TABLE_NAME}")
    
    while True:
        try:
            # Receive messages from SQS
            response = sqs_client.receive_message(
                QueueUrl=SQS_QUEUE_URL,
                MaxNumberOfMessages=1,  # Process one job at a time
                WaitTimeSeconds=20,      # Long polling
                VisibilityTimeout=300    # 5 minutes to process
            )
            
            messages = response.get('Messages', [])
            
            if not messages:
                logger.info("No messages in queue, waiting...")
                continue
            
            # Process each message
            for message in messages:
                try:
                    process_sqs_message(message)
                except Exception as e:
                    logger.error(f"Failed to process message: {e}")
                    # Message will become visible again for retry
            
        except KeyboardInterrupt:
            logger.info("Shutting down worker...")
            break
        except Exception as e:
            logger.error(f"Error in main loop: {e}")
            time.sleep(5)  # Wait before retrying


if __name__ == "__main__":
    main()

