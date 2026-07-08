import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadException implements Exception {
  final String message;
  final dynamic originalError;
  ImageUploadException(this.message, [this.originalError]);
  @override
  String toString() => 'ImageUploadException: $message';
}

class ImageValidationException extends ImageUploadException {
  ImageValidationException(String message, [dynamic error]) : super(message, error);
}

class ImageUploadService {
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];
  static final ImageUploadService _instance = ImageUploadService._();
  factory ImageUploadService() => _instance;
  ImageUploadService._();

  late final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _validateImage(File imageFile) async {
    if (!await imageFile.exists()) {
      throw ImageValidationException('Image file does not exist');
    }

    final fileSize = await imageFile.length();
    if (fileSize > maxFileSizeBytes) {
      throw ImageValidationException(
        'Image too large: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB (max 10MB)',
      );
    }

    if (fileSize < 1024) {
      throw ImageValidationException('Image file too small');
    }

    final extension = imageFile.path.split('.').last.toLowerCase();
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    if (!allowedExtensions.contains(extension)) {
      throw ImageValidationException(
        'Invalid file type: $extension. Allowed: ${allowedExtensions.join(", ")}',
      );
    }
  }

  Future<String?> uploadImage({
    required String userId,
    required File imageFile,
    required String folder,
  }) async {
    try {
      if (userId.isEmpty) {
        throw ImageValidationException('User ID cannot be empty');
      }

      if (folder.isEmpty) {
        throw ImageValidationException('Folder cannot be empty');
      }

      await _validateImage(imageFile);

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final storagePath = '$folder/$userId/$fileName';

      debugPrint('📤 Uploading image to: $storagePath');

      final response = await _supabase.storage
          .from('artworks')
          .upload(
            storagePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      debugPrint('✅ Image uploaded successfully: $response');
      return response;
    } on ImageUploadException {
      rethrow;
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      throw ImageUploadException('Failed to upload image', e);
    }
  }

  String getPublicUrl(String storagePath) {
    try {
      if (storagePath.isEmpty) {
        throw ImageValidationException('Storage path cannot be empty');
      }
      final url = _supabase.storage.from('artworks').getPublicUrl(storagePath);
      debugPrint('🔗 Public URL: $url');
      return url;
    } catch (e) {
      debugPrint('❌ Error getting public URL: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadArtworkImage(File imageFile) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
    final storagePath = await uploadImage(
      userId: userId,
      imageFile: imageFile,
      folder: 'artworks',
    );
    if (storagePath == null) {
      throw ImageUploadException('Upload failed');
    }
    final imageUrl = getPublicUrl(storagePath);
    return {'image_url': imageUrl};
  }

  Future<void> deleteImage(String storagePath) async {
    try {
      if (storagePath.isEmpty) {
        throw ImageValidationException('Storage path cannot be empty');
      }

      await _supabase.storage.from('artworks').remove([storagePath]);
      debugPrint('🗑️ Image deleted: $storagePath');
    } catch (e) {
      debugPrint('❌ Error deleting image: $e');
      throw ImageUploadException('Failed to delete image', e);
    }
  }

  Future<Map<String, dynamic>?> getImageMetadata(String storagePath) async {
    try {
      if (storagePath.isEmpty) {
        throw ImageValidationException('Storage path cannot be empty');
      }

      final metadata = await _supabase.storage
          .from('artworks')
          .info(storagePath);

      return {
        'name': metadata.name,
        'size': metadata.metadata?['size'],
        'created': metadata.metadata?['created'],
        'updated': metadata.metadata?['updated'],
      };
    } catch (e) {
      debugPrint('⚠️ Error getting image metadata: $e');
      return null;
    }
  }

  String getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
