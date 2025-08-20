import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;
  List<CameraDescription>? get cameras => _cameras;

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        _isInitialized = true;
      }
    } catch (e) {
      throw Exception('Failed to initialize camera: $e');
    }
  }

  Future<XFile?> captureImage() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    try {
      final image = await _controller!.takePicture();
      return image;
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  Future<File?> pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }

  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      return;
    }

    final currentIndex = _cameras!.indexOf(_controller!.description);
    final nextIndex = (currentIndex + 1) % _cameras!.length;
    
    await _controller!.dispose();
    _controller = CameraController(
      _cameras![nextIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();
  }

  Future<void> toggleFlash() async {
    if (_controller == null) return;

    try {
      if (_controller!.value.flashMode == FlashMode.off) {
        await _controller!.setFlashMode(FlashMode.torch);
      } else {
        await _controller!.setFlashMode(FlashMode.off);
      }
    } catch (e) {
      // Flash not available on this device
    }
  }
}
