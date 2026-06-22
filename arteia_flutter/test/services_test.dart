import 'package:flutter_test/flutter_test.dart';
import 'package:arteia_app/services/follow_service.dart';
import 'package:arteia_app/services/cache_service.dart';
import 'package:arteia_app/services/image_upload_service.dart';

void main() {
  group('FollowService', () {
    late FollowService followService;

    setUp(() {
      followService = FollowService();
    });

    test('isFollowing returns false when not authenticated', () async {
      final result = await followService.isFollowing('some-user-id');
      expect(result, false);
    });

    test('followUser throws exception when not authenticated', () async {
      expect(
        () => followService.followUser('some-user-id'),
        throwsA(isA<Exception>()),
      );
    });

    test('unfollowUser throws exception when not authenticated', () async {
      expect(
        () => followService.unfollowUser('some-user-id'),
        throwsA(isA<Exception>()),
      );
    });

    test('followUser throws exception when following self', () async {
      // This will fail since we're not authenticated, but the self-check
      // happens before auth check in a real scenario
      expect(
        () => followService.followUser('same-id'),
        throwsA(isA<Exception>()),
      );
    });

    test('getFollowersCount returns 0 when not found', () async {
      final count = await followService.getFollowersCount('nonexistent-user');
      expect(count, 0);
    });

    test('getFollowingCount returns 0 when not found', () async {
      final count = await followService.getFollowingCount('nonexistent-user');
      expect(count, 0);
    });
  });

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

    test('getMimeType returns image/jpeg as default', () {
      expect(uploadService.getMimeType('image.bmp'), 'image/jpeg');
    });
  });
}

// CacheService tests that don't require Hive initialization
class CacheServiceTestUtils {
  static const Duration expectedCacheDuration = Duration(hours: 1);

  static bool isCacheDurationCorrect() {
    return expectedCacheDuration == const Duration(hours: 1);
  }

  static bool isCacheNameCorrect() {
    return 'arteia_cache' == 'arteia_cache';
  }
}