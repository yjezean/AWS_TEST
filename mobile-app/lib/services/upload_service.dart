import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class UploadService {
  final Dio _dio = Dio();
  final ApiClient _api = ApiClient();

  Future<String> uploadImage(File imageFile) async {
    try {
      // TODO: Call API Gateway to get presigned URL
      final filename = imageFile.path.split('/').last;
      final presign =
          await _api.post<Map<String, dynamic>>('/uploads/presign', data: {
        'filename': filename,
        'contentType': 'application/octet-stream',
      });
      final data = presign.data as Map<String, dynamic>;
      final url = data['url'] as String;

      final bytes = await imageFile.readAsBytes();
      await _dio.put(url,
          data: bytes,
          options:
              Options(headers: {'Content-Type': 'application/octet-stream'}));
      return data['key']?.toString() ??
          url; // Prefer returning S3 key if provided
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String> uploadImageFromPath(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      return await uploadImage(imageFile);
    } catch (e) {
      throw Exception('Failed to upload image from path: $e');
    }
  }
}
