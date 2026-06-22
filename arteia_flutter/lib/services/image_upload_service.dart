import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';
import 'image_compression_service.dart';

class ImageUploadService {
  final SupabaseService _supabase = SupabaseService();
  final ImageCompressionService _compression = ImageCompressionService();
  final Uuid _uuid = const Uuid();

  SupabaseClient get _client => _supabase.client;

  /// Upload an image to Supabase Storage and return the public URL
  Future<Map<String, dynamic>> uploadArtworkImage(File imageFile, {bool compress = true}) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise pour uploader une image.');

    // Compress the image if requested
    File processedFile = imageFile;
    if (compress) {
      processedFile = await _compression.compressImage(imageFile);
    }

    // Generate a unique file name
    final fileExt = p.extension(imageFile.path).toLowerCase();
    final fileName = '${_uuid.v4()}$fileExt';
    final filePath = '${user.id}/$fileName';

    // Get file size
    final fileSize = await processedFile.length();

    // Upload to Supabase Storage (newer SDK returns String path on success)
    final response = await _client.storage
        .from('artworks')
        .upload(filePath, processedFile, fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ));

    // The upload returns the path string on success, throws on failure
    if (response.isEmpty) {
      throw Exception('Erreur upload: response was empty');
    }

    // Get public URL
    final publicUrl = _client.storage.from('artworks').getPublicUrl(filePath);

    // Generate thumbnail URL (same image for now, can be optimized)
    final thumbnailUrl = publicUrl;

    return {
      'image_url': publicUrl,
      'image_thumbnail_url': thumbnailUrl,
      'file_size': fileSize,
      'file_path': filePath,
    };
  }

  /// Delete an image from storage
  Future<void> deleteImage(String filePath) async {
    try {
      await _client.storage.from('artworks').remove([filePath]);
    } catch (e) {
      print('🔴 Error deleting image: $e');
    }
  }

  /// Get the MIME type from file extension
  String getMimeType(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Get image dimensions (async)
  Future<Map<String, int>> getImageDimensions(File file) async {
    try {
      final bytes = await file.readAsBytes();
      // Simple dimension detection for JPEG/PNG
      if (bytes.length > 24) {
        if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
          // JPEG
          int offset = 2;
          while (offset < bytes.length - 1) {
            if (bytes[offset] == 0xFF && bytes[offset + 1] == 0xC0) {
              final height = (bytes[offset + 5] << 8) | bytes[offset + 6];
              final width = (bytes[offset + 7] << 8) | bytes[offset + 8];
              return {'width': width, 'height': height};
            }
            offset++;
          }
        } else if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
          // PNG
          final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
          final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
          return {'width': width, 'height': height};
        }
      }
    } catch (e) {
      print('🔴 Error getting dimensions: $e');
    }
    return {'width': 0, 'height': 0};
  }
}