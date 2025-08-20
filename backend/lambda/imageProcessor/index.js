const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const pinpoint = new AWS.Pinpoint();
const axios = require('axios');

// Configure AWS region
AWS.config.update({ region: process.env.AWS_REGION || 'us-east-1' });

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));

    try {
        // Parse the GraphQL event
        const { imageUrl, userId } = event.arguments || {};

        if (!imageUrl || !userId) {
            throw new Error('Missing required parameters: imageUrl and userId');
        }

        // Download image from S3
        console.log('Downloading image from S3:', imageUrl);
        const imageData = await downloadImageFromS3(imageUrl);

        // Process image with YOLOv11
        console.log('Processing image with YOLOv11');
        const detections = await processImageWithYOLO(imageData);

        // Send notification via Pinpoint
        console.log('Sending notification via Pinpoint');
        await sendNotification(userId, detections);

        // Return results
        const response = {
            success: true,
            message: 'Image processed successfully',
            detections: detections,
            imageId: generateImageId(imageUrl)
        };

        console.log('Response:', JSON.stringify(response, null, 2));
        return response;

    } catch (error) {
        console.error('Error processing image:', error);

        return {
            success: false,
            message: `Error processing image: ${error.message}`,
            detections: [],
            imageId: null
        };
    }
};

async function downloadImageFromS3(imageUrl) {
    try {
        // Extract bucket and key from the S3 URL
        const urlParts = imageUrl.split('/');
        const bucket = urlParts[2].split('.')[0];
        const key = urlParts.slice(3).join('/');

        const params = {
            Bucket: bucket,
            Key: key
        };

        const result = await s3.getObject(params).promise();
        return result.Body;

    } catch (error) {
        console.error('Error downloading image from S3:', error);
        throw new Error(`Failed to download image: ${error.message}`);
    }
}

async function processImageWithYOLO(imageData) {
    try {
        // For production, you would integrate with a YOLOv11 endpoint
        // This could be:
        // 1. SageMaker endpoint
        // 2. ECS/Fargate service
        // 3. External API
        // 4. Lambda layer with ONNX runtime

        // For now, we'll simulate the processing
        console.log('Simulating YOLOv11 processing...');

        // Simulate processing time
        await new Promise(resolve => setTimeout(resolve, 2000));

        // Mock detection results
        const mockDetections = [
            {
                label: 'person',
                confidence: 0.95,
                bbox: [100, 150, 300, 500]
            },
            {
                label: 'car',
                confidence: 0.87,
                bbox: [400, 200, 600, 350]
            },
            {
                label: 'building',
                confidence: 0.78,
                bbox: [50, 50, 700, 400]
            }
        ];

        return mockDetections;

    } catch (error) {
        console.error('Error processing image with YOLO:', error);
        throw new Error(`YOLO processing failed: ${error.message}`);
    }
}

async function sendNotification(userId, detections) {
    try {
        const pinpointAppId = process.env.PINPOINT_APP_ID;

        if (!pinpointAppId) {
            console.warn('PINPOINT_APP_ID not configured, skipping notification');
            return;
        }

        const detectionCount = detections.length;
        const topDetection = detections.length > 0 ? detections[0] : null;

        const message = {
            ApplicationId: pinpointAppId,
            MessageRequest: {
                Addresses: {
                    [userId]: {
                        ChannelType: 'PUSH'
                    }
                },
                MessageConfiguration: {
                    DefaultPushNotificationMessage: {
                        Title: 'Image Analysis Complete',
                        Body: `Found ${detectionCount} objects${topDetection ? ` including ${topDetection.label}` : ''}`,
                        Data: JSON.stringify({
                            detections: detections,
                            timestamp: new Date().toISOString()
                        })
                    }
                }
            }
        };

        await pinpoint.sendMessages(message).promise();
        console.log('Notification sent successfully');

    } catch (error) {
        console.error('Error sending notification:', error);
        // Don't throw error for notification failures
    }
}

function generateImageId(imageUrl) {
    // Generate a unique ID based on the image URL and timestamp
    const timestamp = Date.now();
    const urlHash = require('crypto').createHash('md5').update(imageUrl).digest('hex');
    return `${urlHash}_${timestamp}`;
}

// Alternative implementation using SageMaker endpoint
async function processImageWithSageMaker(imageData) {
    try {
        const sageMaker = new AWS.SageMakerRuntime();
        const endpointName = process.env.SAGEMAKER_ENDPOINT_NAME;

        if (!endpointName) {
            throw new Error('SAGEMAKER_ENDPOINT_NAME not configured');
        }

        const params = {
            EndpointName: endpointName,
            ContentType: 'application/x-image',
            Body: imageData
        };

        const result = await sageMaker.invokeEndpoint(params).promise();
        const predictions = JSON.parse(result.Body.toString());

        // Convert predictions to detection format
        const detections = predictions.map(pred => ({
            label: pred.label,
            confidence: pred.confidence,
            bbox: pred.bbox
        }));

        return detections;

    } catch (error) {
        console.error('Error processing with SageMaker:', error);
        throw error;
    }
}
