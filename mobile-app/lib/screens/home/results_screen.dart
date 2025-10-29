import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../../models/processing_models.dart';
import '../../services/processing_service.dart';

class ResultsScreen extends StatefulWidget {
  final String imagePath;
  final String imageUrl;
  final Uint8List? imageBytes;

  const ResultsScreen({
    super.key,
    required this.imagePath,
    required this.imageUrl,
    this.imageBytes,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ProcessingService _processingService = ProcessingService();
  final GlobalKey _imageKey = GlobalKey();
  ui.Size? _imageSize;
  List<DetectionResult> _detections = [];
  String _status = 'PENDING';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _processImage();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    if (widget.imageBytes != null) {
      // Use MemoryImage for web (works with bytes)
      final imageProvider = MemoryImage(widget.imageBytes!);
      imageProvider.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((info, _) {
          if (mounted) {
            setState(() {
              _imageSize = ui.Size(
                info.image.width.toDouble(),
                info.image.height.toDouble(),
              );
            });
          }
        }),
      );
    }
    // On web, if no bytes, skip size detection (image will still display)
  }

  Future<void> _processImage() async {
    try {
      // Submit processing job
      final submitResponse = await _processingService.submitProcessing(
        imageKeyOrUrl: widget.imageUrl,
      );

      // Poll for results
      await _pollJobStatus(submitResponse.jobId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'FAILED';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Processing failed: $e')),
        );
      }
    }
  }

  Future<void> _pollJobStatus(String jobId) async {
    while (_status != 'COMPLETED' && _status != 'FAILED' && mounted) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final status = await _processingService.getJobStatus(jobId);
        if (mounted) {
          setState(() {
            _status = status.status;
            _detections = status.detections;
            if (status.status == 'COMPLETED' || status.status == 'FAILED') {
              _isLoading = false;
            }
          });
          if (_status == 'COMPLETED' || _status == 'FAILED') {
            break;
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _status = 'FAILED';
            _isLoading = false;
          });
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Results'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with detections overlay
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    widget.imageBytes != null
                        ? Image.memory(
                            widget.imageBytes!,
                            fit: BoxFit.contain,
                            key: _imageKey,
                            width: double.infinity,
                            height: 300,
                          )
                        : Container(
                            width: double.infinity,
                            height: 300,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image,
                                  size: 64, color: Colors.grey),
                            ),
                          ),
                    if (_imageSize != null && _detections.isNotEmpty)
                      CustomPaint(
                        size: Size.infinite,
                        painter: DetectionPainter(
                          detections: _detections,
                          imageSize: _imageSize!,
                          displaySize: Size(
                            MediaQuery.of(context).size.width - 32,
                            300,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Status
            Text(
              'Status: $_status',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Detections list
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_detections.isEmpty)
              const Text('No objects detected')
            else
              ..._detections.map((detection) => Card(
                    child: ListTile(
                      title: Text(detection.label),
                      subtitle: Text(
                        'Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%',
                      ),
                      trailing: Text(
                        'BBox: ${detection.bbox.map((e) => e.toStringAsFixed(1)).join(", ")}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final ui.Size imageSize;
  final Size displaySize;

  DetectionPainter({
    required this.detections,
    required this.imageSize,
    required this.displaySize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = displaySize.width / imageSize.width;
    final scaleY = displaySize.height / imageSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final offsetX = (displaySize.width - imageSize.width * scale) / 2;
    final offsetY = (displaySize.height - imageSize.height * scale) / 2;

    for (final detection in detections) {
      if (detection.bbox.length >= 4) {
        final x = detection.bbox[0] * scale + offsetX;
        final y = detection.bbox[1] * scale + offsetY;
        final w = detection.bbox[2] * scale;
        final h = detection.bbox[3] * scale;

        final paint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);

        final textPainter = TextPainter(
          text: TextSpan(
            text:
                '${detection.label} ${(detection.confidence * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final backgroundPaint = Paint()..color = Colors.white.withOpacity(0.8);
        canvas.drawRect(
          Rect.fromLTWH(
              x, y - textPainter.height, textPainter.width, textPainter.height),
          backgroundPaint,
        );
        textPainter.paint(canvas, Offset(x, y - textPainter.height));
      }
    }
  }

  @override
  bool shouldRepaint(DetectionPainter oldDelegate) {
    return detections != oldDelegate.detections ||
        imageSize != oldDelegate.imageSize ||
        displaySize != oldDelegate.displaySize;
  }
}
