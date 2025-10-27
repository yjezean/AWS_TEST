class SubmitJobRequest {
  final String imageKeyOrUrl; // s3 key or pre-signed URL

  const SubmitJobRequest({required this.imageKeyOrUrl});

  Map<String, dynamic> toJson() => {
        'image': imageKeyOrUrl,
      };
}

class SubmitJobResponse {
  final String jobId;

  const SubmitJobResponse({required this.jobId});

  factory SubmitJobResponse.fromJson(Map<String, dynamic> json) {
    return SubmitJobResponse(jobId: json['jobId']?.toString() ?? '');
  }
}

class DetectionResult {
  final String label;
  final double confidence;
  final List<double> bbox;

  const DetectionResult(
      {required this.label, required this.confidence, required this.bbox});

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    final bboxList =
        (json['bbox'] as List?)?.map((e) => (e as num).toDouble()).toList() ??
            <double>[];
    return DetectionResult(
      label: json['label']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      bbox: bboxList,
    );
  }
}

class JobStatusResponse {
  final String status; // PENDING, RUNNING, COMPLETED, FAILED
  final List<DetectionResult> detections;
  final String? message;

  const JobStatusResponse(
      {required this.status, required this.detections, this.message});

  factory JobStatusResponse.fromJson(Map<String, dynamic> json) {
    final detectionsJson = (json['detections'] as List?) ?? [];
    return JobStatusResponse(
      status: json['status']?.toString() ?? 'PENDING',
      detections: detectionsJson
          .map((e) => DetectionResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message']?.toString(),
    );
  }
}
