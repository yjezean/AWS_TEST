import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';

class UploadService {
  final Dio _dio = Dio();
  final ApiClient _api = ApiClient();

  Future<String> uploadImageFromXFile(XFile imageFile) async {
    try {
      // Extract filename - works on both mobile and web
      String filename = imageFile.name;
      if (filename.isEmpty || !filename.contains('.')) {
        // Fallback: extract from path if name is empty
        final path = imageFile.path;
        if (path.isNotEmpty) {
          filename = path.split(RegExp(r"[\\/]")).last;
        } else {
          filename = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        }
      }

      // Get presigned URL
      final presign = await _api.post<Map<String, dynamic>>('/upload', data: {
        'filename': filename,
        'contentType': 'application/octet-stream',
      });
      final data = presign.data as Map<String, dynamic>;
      final url = data['url'] as String;
      final bucket = data['bucket']?.toString();
      final key = data['key']?.toString();

      // Read bytes from XFile (works on both web and mobile)
      final bytes = await imageFile.readAsBytes();

      // Upload to S3
      await _dio.put(url,
          data: bytes,
          options:
              Options(headers: {'Content-Type': 'application/octet-stream'}));

      // Return S3 URL for processing API
      if (bucket != null && key != null) {
        return 's3://$bucket/$key';
      }
      return url;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
