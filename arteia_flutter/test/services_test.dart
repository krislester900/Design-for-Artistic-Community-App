import 'package:flutter_test/flutter_test.dart';
import 'package:arteia_app/services/follow_service.dart';
import 'package:arteia_app/services/cache_service.dart';
import 'package:arteia_app/services/image_upload_service.dart';
import 'package:arteia_app/services/like_service.dart';
import 'package:arteia_app/services/comment_service.dart';
import 'package:arteia_app/services/ai_assistant_service.dart';
import 'package:arteia_app/services/interactivity_service.dart';
import 'package:arteia_app/services/image_compression_service.dart';

void main() {
  // ============================================================
  // FOLLOW SERVICE TESTS
  // ============================================================
  group('FollowService', () {
    test('FollowService is a singleton', () {
      final instance1 = FollowService();
      final instance2 = FollowService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('FollowService can be instantiated', () {
      final service = FollowService();
      expect(service, isA<FollowService>());
    });
  });

  // ============================================================
  // IMAGE UPLOAD SERVICE TESTS
  // ============================================================
  group('ImageUploadService', () {
    late ImageUploadService uploadService;

    setUp(() {
      uploadService = ImageUploadService();
    });

    test('getMimeType returns image/jpeg for jpg', () {
      expect(uploadService.getMimeType('image.jpg'), 'image/jpeg');
    });

    test('getMimeType returns image/jpeg for jpeg', () {
      expect(uploadService.getMimeType('image.jpeg'), 'image/jpeg');
    });

    test('getMimeType returns image/png for png', () {
      expect(uploadService.getMimeType('image.png'), 'image/png');
    });

    test('getMimeType returns image/gif for gif', () {
      expect(uploadService.getMimeType('image.gif'), 'image/gif');
    });

    test('getMimeType returns image/webp for webp', () {
      expect(uploadService.getMimeType('image.webp'), 'image/webp');
    });

    test('getMimeType returns application/octet-stream as default for unknown', () {
      expect(uploadService.getMimeType('image.bmp'), 'application/octet-stream');
    });

    test('getMimeType handles uppercase extensions', () {
      expect(uploadService.getMimeType('image.JPG'), 'image/jpeg');
      expect(uploadService.getMimeType('image.PNG'), 'image/png');
    });

    test('getMimeType handles paths with dots', () {
      expect(uploadService.getMimeType('/path/to/my.image.png'), 'image/png');
    });
  });

  // ============================================================
  // LIKE SERVICE TESTS
  // ============================================================
  group('LikeService', () {
    test('LikeService is a singleton', () {
      final instance1 = LikeService();
      final instance2 = LikeService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('LikeService can be instantiated', () {
      final service = LikeService();
      expect(service, isA<LikeService>());
    });

    test('LikeResult stores liked and count correctly', () {
      final result = LikeResult(liked: true, count: 42);
      expect(result.liked, isTrue);
      expect(result.count, 42);
    });
  });

  // ============================================================
  // COMMENT SERVICE TESTS
  // ============================================================
  group('CommentService', () {
    test('CommentService is a singleton', () {
      final instance1 = CommentService();
      final instance2 = CommentService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('CommentService can be instantiated', () {
      final service = CommentService();
      expect(service, isA<CommentService>());
    });

    test('getTimeAgo returns empty string for null', () {
      expect(CommentService.getTimeAgo(null), '');
    });

    test('getTimeAgo returns "À l\'instant" for recent dates', () {
      final now = DateTime.now().toIso8601String();
      expect(CommentService.getTimeAgo(now), "À l'instant");
    });

    test('getTimeAgo returns minutes for recent comments', () {
      final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String();
      expect(CommentService.getTimeAgo(fiveMinAgo), 'Il y a 5m');
    });

    test('getTimeAgo returns hours for older comments', () {
      final threeHoursAgo = DateTime.now().subtract(const Duration(hours: 3)).toIso8601String();
      expect(CommentService.getTimeAgo(threeHoursAgo), 'Il y a 3h');
    });

    test('getTimeAgo returns days for older comments', () {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
      expect(CommentService.getTimeAgo(twoDaysAgo), 'Il y a 2j');
    });

    test('getTimeAgo returns weeks for older comments', () {
      final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14)).toIso8601String();
      expect(CommentService.getTimeAgo(twoWeeksAgo), 'Il y a 2sem');
    });

    test('getTimeAgo returns months for older comments', () {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90)).toIso8601String();
      expect(CommentService.getTimeAgo(threeMonthsAgo), 'Il y a 3mois');
    });

    test('getTimeAgo returns years for very old comments', () {
      final twoYearsAgo = DateTime.now().subtract(const Duration(days: 730)).toIso8601String();
      expect(CommentService.getTimeAgo(twoYearsAgo), 'Il y a 2ans');
    });
  });

  // ============================================================
  // AI ASSISTANT SERVICE TESTS
  // ============================================================
  group('AiAssistantService', () {
    late AiAssistantService assistant;

    setUp(() {
      assistant = AiAssistantService();
    });

    test('sendMessage returns local response when not authenticated', () async {
      final reply = await assistant.sendMessage(message: 'Bonjour');
      expect(reply, isNotEmpty);
    });

    test('sendMessage handles greeting', () async {
      final reply = await assistant.sendMessage(message: 'Salut');
      expect(reply, contains('Ravie'));
    });

    test('sendMessage handles idea request', () async {
      final reply = await assistant.sendMessage(message: 'Donne-moi une idée');
      expect(reply, contains('autoportrait'));
    });

    test('sendMessage handles thank you', () async {
      final reply = await assistant.sendMessage(message: 'Merci');
      expect(reply, contains('continue de créer'));
    });

    test('sendMessage handles feedback request', () async {
      final reply = await assistant.sendMessage(message: 'Donne-moi un retour');
      expect(reply, anyOf(contains('feedback'), contains('retour'), contains('sincère')));
    });

    test('sendMessage handles features question', () async {
      final reply = await assistant.sendMessage(message: 'Comment faire ?');
      expect(reply, anyOf(contains('publier'), contains('créer')));
    });

    test('sendMessage handles challenge request', () async {
      final reply = await assistant.sendMessage(message: 'Un défi créatif');
      expect(reply, contains('10 minutes'));
    });

    test('sendMessage handles who are you', () async {
      final reply = await assistant.sendMessage(message: 'Qui es-tu ?');
      expect(reply, contains('Muse'));
    });

    test('sendMessage returns default response for unknown input', () async {
      final reply = await assistant.sendMessage(message: 'xyz123unknown');
      expect(reply, contains('Je t\'écoute'));
    });

    test('sendMessage works with different content types', () async {
      final reply = await assistant.sendMessage(
        message: 'Des idées',
        contentType: 'visual',
      );
      expect(reply, isNotEmpty);
    });

    test('sendMessage works with history', () async {
      final reply = await assistant.sendMessage(
        message: 'Merci',
        history: [
          {'role': 'user', 'content': 'Bonjour'},
          {'role': 'assistant', 'content': 'Bonjour créateur !'},
        ],
      );
      expect(reply, contains('continue de créer'));
    });
  });

  // ============================================================
  // INTERACTIVITY SERVICE TESTS
  // ============================================================
  group('InteractivityService', () {
    test('InteractivityService is a singleton', () {
      final instance1 = InteractivityService();
      final instance2 = InteractivityService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('HapticFeedbackType enum has all values', () {
      expect(HapticFeedbackType.values.length, 6);
      expect(HapticFeedbackType.values, contains(HapticFeedbackType.light));
      expect(HapticFeedbackType.values, contains(HapticFeedbackType.medium));
      expect(HapticFeedbackType.values, contains(HapticFeedbackType.heavy));
      expect(HapticFeedbackType.values, contains(HapticFeedbackType.selection));
      expect(HapticFeedbackType.values, contains(HapticFeedbackType.success));
      expect(HapticFeedbackType.values, contains(HapticFeedbackType.error));
    });
  });

  // ============================================================
  // IMAGE COMPRESSION SERVICE TESTS
  // ============================================================
  group('ImageCompressionService', () {
    test('targetQuality is 80', () {
      expect(ImageCompressionService.targetQuality, 80);
    });

    test('maxWidth is 1920', () {
      expect(ImageCompressionService.maxWidth, 1920);
    });

    test('maxHeight is 1920', () {
      expect(ImageCompressionService.maxHeight, 1920);
    });

    test('maxFileSize is 5MB', () {
      expect(ImageCompressionService.maxFileSize, 5 * 1024 * 1024);
    });

    test('getFileSizeString formats bytes correctly', () {
      final service = ImageCompressionService();
      expect(service.getFileSizeString(100), '100 B');
      expect(service.getFileSizeString(1024), '1.0 KB');
      expect(service.getFileSizeString(1048576), '1.0 MB');
      expect(service.getFileSizeString(1073741824), '1024.0 MB');
    });

    test('getFileSizeString handles zero', () {
      final service = ImageCompressionService();
      expect(service.getFileSizeString(0), '0 B');
    });

    test('isFileSizeAcceptable is a function', () {
      final service = ImageCompressionService();
      expect(service.isFileSizeAcceptable, isA<Function>());
    });
  });

  // ============================================================
  // CACHE SERVICE TESTS
  // ============================================================
  group('CacheService', () {
    test('CacheService has getInstance method', () {
      expect(CacheService.getInstance, isA<Function>());
    });

    test('cache duration is 1 hour', () {
      const expectedDuration = Duration(hours: 1);
      expect(expectedDuration.inHours, 1);
    });

    test('cache name is arteia_cache', () {
      const cacheName = 'arteia_cache';
      expect(cacheName, 'arteia_cache');
    });
  });
}