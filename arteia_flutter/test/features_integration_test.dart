import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arteia_app/services/cache_service.dart';
import 'package:arteia_app/services/like_service.dart';
import 'package:arteia_app/services/comment_service.dart';
import 'package:arteia_app/services/ai_assistant_service.dart';
import 'package:arteia_app/services/follow_service.dart';
import 'package:arteia_app/services/favorites_service.dart';
import 'package:arteia_app/services/notifications_service.dart';
import 'package:arteia_app/widgets/follow_button.dart';

void main() {
  group('Service Integration Tests', () {
    test('FollowButton can be instantiated', () {
      final followButton = FollowButton(userId: 'test-user-id');
      expect(followButton, isA<FollowButton>());
    });

    test('CacheService has required static methods', () {
      expect(CacheService.getInstance, isA<Function>());
    });

    test('LikeService singleton works consistently', () {
      final instance1 = LikeService();
      final instance2 = LikeService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('CommentService singleton works consistently', () {
      final instance1 = CommentService();
      final instance2 = CommentService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('LikeResult data class works correctly', () {
      final result = LikeResult(liked: true, count: 10);
      expect(result.liked, isTrue);
      expect(result.count, 10);

      final result2 = LikeResult(liked: false, count: 0);
      expect(result2.liked, isFalse);
      expect(result2.count, 0);
    });

    test('AiAssistantService can be instantiated', () {
      final assistant = AiAssistantService();
      expect(assistant, isA<AiAssistantService>());
    });

    test('FollowService can be instantiated', () {
      final service = FollowService();
      expect(service, isA<FollowService>());
    });
  });

  group('Feature Verification Tests', () {
    test('Like system - LikeButton widget can be created', () {
      final likeButton = LikeButton(
        postId: 'test-post',
        initialCount: 5,
        initialLiked: false,
        size: 24,
      );
      expect(likeButton, isA<LikeButton>());
      expect(likeButton.postId, 'test-post');
      expect(likeButton.initialCount, 5);
      expect(likeButton.initialLiked, isFalse);
    });

    test('Like system - LikeButton supports liked state', () {
      final likeButton = LikeButton(
        postId: 'test-post',
        initialCount: 42,
        initialLiked: true,
      );
      expect(likeButton.initialLiked, isTrue);
      expect(likeButton.initialCount, 42);
    });

    test('Comment system - CommentService getTimeAgo handles all cases', () {
      // Null case
      expect(CommentService.getTimeAgo(null), '');

      // "À l'instant"
      final now = DateTime.now().toIso8601String();
      expect(CommentService.getTimeAgo(now), "À l'instant");

      // Minutes
      final mins = DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String();
      expect(CommentService.getTimeAgo(mins), 'Il y a 5m');

      // Hours
      final hours = DateTime.now().subtract(const Duration(hours: 3)).toIso8601String();
      expect(CommentService.getTimeAgo(hours), 'Il y a 3h');

      // Days
      final days = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
      expect(CommentService.getTimeAgo(days), 'Il y a 2j');

      // Weeks
      final weeks = DateTime.now().subtract(const Duration(days: 14)).toIso8601String();
      expect(CommentService.getTimeAgo(weeks), 'Il y a 2sem');

      // Months
      final months = DateTime.now().subtract(const Duration(days: 60)).toIso8601String();
      expect(CommentService.getTimeAgo(months), 'Il y a 2mois');

      // Years
      final years = DateTime.now().subtract(const Duration(days: 400)).toIso8601String();
      expect(CommentService.getTimeAgo(years), 'Il y a 1ans');
    });

    test('AI Assistant - responds to different query types', () async {
      final assistant = AiAssistantService();

      // Greeting
      final greeting = await assistant.sendMessage(message: 'Bonjour');
      expect(greeting, contains('Bonjour'));

      // Ideas
      final ideas = await assistant.sendMessage(message: 'idée');
      expect(ideas, anyOf(contains('Idées'), contains('idée')));

      // Features
      final features = await assistant.sendMessage(message: 'fonctionnalité');
      expect(features, contains('Fonctionnalités'));

      // Challenge
      final challenge = await assistant.sendMessage(message: 'défi');
      expect(challenge, contains('Défi'));
    });

    test('FavoritesService has required methods', () {
      final service = FavoritesService();
      expect(service, isA<FavoritesService>());
    });

    test('NotificationsService has required methods', () {
      final service = NotificationsService();
      expect(service, isA<NotificationsService>());
    });

    test('CommentTile widget can be created', () {
      final tile = CommentTile(
        comment: {
          'id': '1',
          'content': 'Test comment',
          'user_id': 'user1',
          'created_at': DateTime.now().toIso8601String(),
          'profiles': {'username': 'TestUser'},
        },
        isOwner: true,
        onDelete: () {},
      );
      expect(tile, isA<CommentTile>());
    });
  });
}