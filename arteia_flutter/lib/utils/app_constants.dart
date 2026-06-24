class AppConstants {
  // Timing
  static const Duration loadingScreenMinDuration = Duration(milliseconds: 500);
  static const Duration connectivityCheckInterval = Duration(seconds: 30);
  static const Duration connectivityTimeout = Duration(seconds: 5);
  static const Duration snackBarDuration = Duration(seconds: 3);

  // Cache
  static const int maxImageCacheSize = 100;
  static const int maxCacheAgeDays = 7;
  static const int postsPerPage = 20;
  static const int commentsPerPage = 10;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxBioLength = 150;
  static const int maxCommentLength = 500;
  static const int maxTitleLength = 100;

  // Image
  static const int imageCompressionQuality = 80;
  static const int imageMaxWidth = 1920;
  static const int imageMaxHeight = 1920;
  static const int imageMaxFileSizeMB = 5;

  // Animation
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);

  // Pagination
  static const int infiniteScrollThreshold = 5;

  // Colors
  static const String primaryColorHex = '#7C5CFC';
  static const String secondaryColorHex = '#00D4AA';
  static const String accentColorHex = '#FF6B9D';
}