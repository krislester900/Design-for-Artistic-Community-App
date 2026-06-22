import 'package:flutter_test/flutter_test.dart';
import 'package:arteia_app/services/image_compression_service.dart';

void main() {
  late ImageCompressionService compressionService;

  setUp(() {
    compressionService = ImageCompressionService();
  });

  group('ImageCompressionService', () {
    test('getFileSizeString returns correct format for bytes', () {
      expect(compressionService.getFileSizeString(500), '500 B');
    });

    test('getFileSizeString returns correct format for KB', () {
      expect(compressionService.getFileSizeString(2048), '2.0 KB');
    });

    test('getFileSizeString returns correct format for MB', () {
      expect(compressionService.getFileSizeString(5 * 1024 * 1024), '5.0 MB');
    });

    test('maxFileSize is 5 MB', () {
      expect(ImageCompressionService.maxFileSize, 5 * 1024 * 1024);
    });

    test('targetQuality is 80', () {
      expect(ImageCompressionService.targetQuality, 80);
    });

    test('maxWidth is 1920', () {
      expect(ImageCompressionService.maxWidth, 1920);
    });

    test('maxHeight is 1920', () {
      expect(ImageCompressionService.maxHeight, 1920);
    });
  });
}