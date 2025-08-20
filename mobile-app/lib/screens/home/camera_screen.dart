import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../../services/camera_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  bool _isInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera initialization failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _captureImage() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await _cameraService.captureImage();
      if (image != null && mounted) {
        Navigator.pop(context, {
          'imageFile': File(image.path),
          'imagePath': image.path,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_isInitialized && _cameraService.controller != null)
              CameraPreview(_cameraService.controller!),

            // Camera Controls Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Top Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),

                        // Flash Toggle
                        IconButton(
                          onPressed: _cameraService.toggleFlash,
                          icon: const Icon(
                            Icons.flash_on,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Bottom Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery Button
                        IconButton(
                          onPressed: () async {
                            final image = await _cameraService.pickImageFromGallery();
                            if (image != null && mounted) {
                              Navigator.pop(context, {
                                'imageFile': image,
                                'imagePath': image.path,
                              });
                            }
                          },
                          icon: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),

                        // Capture Button
                        GestureDetector(
                          onTap: _isCapturing ? null : _captureImage,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                              color: _isCapturing ? Colors.grey : Colors.white,
                            ),
                            child: _isCapturing
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.black,
                                    size: 40,
                                  ),
                          ),
                        ),

                        // Switch Camera Button
                        IconButton(
                          onPressed: _cameraService.switchCamera,
                          icon: const Icon(
                            Icons.flip_camera_ios,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Instructions
                    const Text(
                      'Tap the button to capture',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading Indicator
            if (!_isInitialized)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
