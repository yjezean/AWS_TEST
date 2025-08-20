import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:io';

class UploadService {
  Future<String> uploadImage(File imageFile) async {
    try {
      final key = 'images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      
      final result = await Amplify.Storage.uploadFile(
        local: imageFile,
        key: key,
        options: StorageUploadFileOptions(
          accessLevel: StorageAccessLevel.private,
          metadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalName': imageFile.path.split('/').last,
          },
        ),
      ).result;
      
      return result.key;
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

  Future<void> deleteImage(String imageKey) async {
    try {
      await Amplify.Storage.remove(
        key: imageKey,
        options: StorageRemoveOptions(
          accessLevel: StorageAccessLevel.private,
        ),
      ).result;
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  Future<String> getImageUrl(String imageKey) async {
    try {
      final result = await Amplify.Storage.getUrl(
        key: imageKey,
        options: StorageGetUrlOptions(
          accessLevel: StorageAccessLevel.private,
          expires: 3600, // 1 hour
        ),
      ).result;
      
      return result.url.toString();
    } catch (e) {
      throw Exception('Failed to get image URL: $e');
    }
  }

  Future<List<StorageItem>> listImages() async {
    try {
      final result = await Amplify.Storage.list(
        options: StorageListOptions(
          accessLevel: StorageAccessLevel.private,
          path: 'images/',
        ),
      ).result;
      
      return result.items;
    } catch (e) {
      throw Exception('Failed to list images: $e');
    }
  }

  Stream<StorageUploadProgress> uploadImageWithProgress(File imageFile) {
    final key = 'images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
    
    return Amplify.Storage.uploadFile(
      local: imageFile,
      key: key,
      options: StorageUploadFileOptions(
        accessLevel: StorageAccessLevel.private,
      ),
    ).progress;
  }
}
