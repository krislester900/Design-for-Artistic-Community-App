import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class ImageCompressionService {
  /// Maximum image size in bytes (5 MB)
  static const int maxFileSize = 5 * 1024 * 1024;
  
  /// Target quality for JPEG compression (0-100)
  static const int targetQuality = 80;

  /// Maximum dimensions for uploaded images
  static const int maxWidth = 1920;
  static const int maxHeight = 1920;

  /// Compress an image file to reduce its size
  Future<File> compressImage(File file, {int? quality, int? maxWidth, int? maxHeight}) async {
    try {
      final fileSize = await file.length();
      
      // If file is already under limit, return as-is
      if (fileSize <= maxFileSize) {
        return file;
      }

      // Read file bytes
      final Uint8List bytes = await file.readAsBytes();
      
      // Use flutter image compression via platform channel
      // For now, use a simple approach: if it's a large JPEG/PNG,
      // we'll rely on the image_picker's imageQuality parameter
      // This service provides a fallback
      
      final compressedBytes = await _compressBytes(bytes, 
        quality: quality ?? targetQuality,
        maxWidth: maxWidth ?? ImageCompressionService.maxWidth,
        maxHeight: maxHeight ?? ImageCompressionService.maxHeight,
      );
      
      // Write compressed bytes to a new temp file
      final tempDir = Directory.systemTemp;
      final tempPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}${_getExtension(file.path)}';
      final compressedFile = await File(tempPath).writeAsBytes(compressedBytes);
      
      return compressedFile;
    } catch (e) {
      print('🔴 Compression error: $e');
      // Return original file if compression fails
      return file;
    }
  }

  /// Compress image bytes (platform-specific implementation)
  Future<Uint8List> _compressBytes(Uint8List bytes, {
    required int quality,
    required int maxWidth,
    required int maxHeight,
  }) async {
    // Use platform channel to compress image
    // This delegates to native image processing
    try {
      final result = await MethodChannel('com.arteia/image_compression')
          .invokeMethod<Uint8List>('compressImage', {
        'bytes': bytes,
        'quality': quality,
        'maxWidth': maxWidth,
        'maxHeight': maxHeight,
      });
      
      if (result != null) {
        return result;
      }
    } catch (e) {
      print('🔴 Platform compression unavailable: $e');
    }
    
    // Fallback: if we can't compress, return original bytes
    // In production, use packages like `flutter_image_compress`
    return bytes;
  }

  /// Get the file extension from a path
  String _getExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1) return '.jpg';
    return path.substring(dotIndex);
  }

  /// Check if a file size is acceptable
  bool isFileSizeAcceptable(File file) {
    final size = file.lengthSync();
    return size <= maxFileSize;
  }

  /// Get human-readable file size
  String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}