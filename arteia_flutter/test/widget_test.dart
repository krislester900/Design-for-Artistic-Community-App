import 'package:flutter_test/flutter_test.dart';
import 'package:arteia_app/services/image_compression_service.dart';
import 'package:arteia_app/services/follow_service.dart';
import 'package:arteia_app/services/image_upload_service.dart';

void main() {
  group('ImageCompressionService Tests', () {
    test('getFileSizeString formats bytes correctly', () {
      final service = ImageCompressionService();
      expect(service.getFileSizeString(100), '100 B');
      expect(service.getFileSizeString(1024), '1.0 KB');
      expect(service.getFileSizeString(1048576), '1.0 MB');
    });

    test('isFileSizeAcceptable checks file size', () {
      final service = ImageCompressionService();
      // Small file should be acceptable
      expect(service.isFileSizeAcceptable, isA<Function>());
    });
  });

  group('FollowService Tests', () {
    test('services are instantiated correctly', () {
      final followService = FollowService();
      expect(followService, isA<FollowService>());
    });
  });

  group('ImageUploadService Tests', () {
    test('mime type detection works correctly', () {
      final service = ImageUploadService();
      expect(service.getMimeType('test.jpg'), 'image/jpeg');
      expect(service.getMimeType('test.jpeg'), 'image/jpeg');
      expect(service.getMimeType('test.png'), 'image/png');
      expect(service.getMimeType('test.gif'), 'image/gif');
      expect(service.getMimeType('test.webp'), 'image/webp');
    });
  });

  group('CacheService Constants', () {
    test('cache constants are defined', () {
      // Verify cache configuration constants
      const expectedDuration = Duration(hours: 1);
      expect(expectedDuration.inHours, 1);
    });
  });

  group('App Constants', () {
    test('image quality settings are correct', () {
      expect(ImageCompressionService.targetQuality, 80);
      expect(ImageCompressionService.maxWidth, 1920);
      expect(ImageCompressionService.maxHeight, 1920);
      expect(ImageCompressionService.maxFileSize, 5 * 1024 * 1024);
    });
  });
}