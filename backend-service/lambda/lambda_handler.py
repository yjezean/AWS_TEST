"""
AWS Lambda handler for image processing requests
Routes jobs to SQS for ECS processing
"""

import json
import boto3
import uuid
from datetime import datetime
import os
from decimal import Decimal

# AWS clients
s3_client = boto3.client('s3')
sqs_client = boto3.client('sqs')
dynamodb = boto3.resource('dynamodb')

# Configuration
SQS_QUEUE_URL = os.environ.get('SQS_QUEUE_URL')
# Prefer DYNAMODB_TABLE env if present, fall back to JOBS_TABLE_NAME, then default
JOBS_TABLE_NAME = os.environ.get('DYNAMODB_TABLE') or os.environ.get('JOBS_TABLE_NAME', 'image-processing-jobs')
S3_BUCKET = os.environ.get('S3_BUCKET')

def process_handler(event, context):
    """Enqueue processing job from imageUrls."""
    try:
        body = json.loads(event.get('body', '{}'))
        image_urls = body.get('imageUrls', [])
        user_id = body.get('userId')
        metadata = body.get('metadata', {})

        if not image_urls:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'No image URLs provided',
                    'message': 'Please provide imageUrls array'
                })
            }

        job_id = str(uuid.uuid4())

        jobs_table = dynamodb.Table(JOBS_TABLE_NAME)
        jobs_table.put_item(
            Item={
                'jobId': job_id,
                'userId': user_id,
                'status': 'PENDING',
                'imageUrls': image_urls,
                'imageCount': len(image_urls),
                'metadata': metadata,
                'createdAt': datetime.utcnow().isoformat(),
                'updatedAt': datetime.utcnow().isoformat()
            }
        )

        sqs_message = {
            'jobId': job_id,
            'imageUrls': image_urls,
            'userId': user_id,
            'metadata': metadata
        }

        sqs_client.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=json.dumps(sqs_message),
            MessageAttributes={
                'JobId': {'StringValue': job_id, 'DataType': 'String'},
                'ImageCount': {'StringValue': str(len(image_urls)), 'DataType': 'Number'}
            }
        )

        return {
            'statusCode': 202,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': True,
                'jobId': job_id,
                'status': 'PENDING',
                'message': f'Job created for {len(image_urls)} image(s)',
                'imageCount': len(image_urls)
            })
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps({'success': False, 'error': str(e)})}


def get_job_status_handler(event, context):
    """
    Get status of a processing job
    
    Path: GET /jobs/{jobId}
    """
    
    try:
        job_id = (event.get('pathParameters') or {}).get('jobId')
        if not job_id:
            # Fallback parse from path like /prod/jobs/{id}
            path = event.get('path', '')
            parts = path.rstrip('/').split('/')
            if parts:
                job_id = parts[-1]
        
        if not job_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Job ID required'})
            }
        
        # Get job from DynamoDB
        jobs_table = dynamodb.Table(JOBS_TABLE_NAME)
        response = jobs_table.get_item(Key={'jobId': job_id})
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Job not found'})
            }
        
        job = response['Item']
        
        def _to_native(obj):
            if isinstance(obj, Decimal):
                # Convert numeric-looking Decimals to float; others to string
                try:
                    return float(obj)
                except Exception:
                    return str(obj)
            if isinstance(obj, list):
                return [_to_native(v) for v in obj]
            if isinstance(obj, dict):
                return {k: _to_native(v) for k, v in obj.items()}
            return obj
        
        job = _to_native(job)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'jobId': job.get('jobId'),
                'status': job.get('status'),
                'imageCount': job.get('imageCount', 0),
                'detections': job.get('detections', []),
                'createdAt': job.get('createdAt'),
                'updatedAt': job.get('updatedAt'),
                'message': job.get('message')
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


def generate_presigned_url_handler(event, context):
    """
    Generate presigned URL for image upload
    
    POST /uploads/presign
    Body: {"filename": "image.jpg", "contentType": "image/jpeg"}
    """
    
    try:
        body = json.loads(event.get('body', '{}'))
        # Accept both camelCase and snake_case
        filename = body.get('filename') or body.get('file_name') or f'{uuid.uuid4()}.jpg'
        content_type = body.get('contentType') or body.get('content_type') or 'image/jpeg'
        
        # Generate unique S3 key
        s3_key = f'uploads/{datetime.utcnow().strftime("%Y/%m/%d")}/{uuid.uuid4()}-{filename}'
        
        # Generate presigned URL
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': S3_BUCKET,
                'Key': s3_key,
                'ContentType': content_type
            },
            ExpiresIn=3600  # 1 hour
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'url': presigned_url,
                'key': s3_key,
                'bucket': S3_BUCKET
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


def lambda_handler(event, context):
    """Dispatcher for API Gateway proxy integration."""
    try:
        method = (event.get('httpMethod') or '').upper()
        resource = event.get('resource') or ''
        path = event.get('path') or ''

        # Normalize for stage prefixes, e.g., /prod/upload
        def _endswith(seg: str):
            return path.rstrip('/').endswith('/' + seg) or resource.rstrip('/').endswith('/' + seg)

        # Route: POST /upload → presign URL
        if method == 'POST' and _endswith('upload'):
            return generate_presigned_url_handler(event, context)

        # Route: GET /jobs/{job_id} → status
        if method == 'GET' and ('/jobs/' in path or '/jobs' in resource):
            return get_job_status_handler(event, context)

        # Default: process request expects imageUrls
        return process_handler(event, context)

    except Exception as e:
        print(f"Error: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}

