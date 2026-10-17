// lib/core/config/supabase_config.dart
// Supabase configuration with environment-based credentials

class SupabaseConfig {
  // These values are injected at compile time via --dart-define
  // Example: flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=xxx
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static void validateOrThrow() {
    if (!isConfigured) {
      final missing = <String>[];
      if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
      if (supabasePublishableKey.isEmpty) {
        missing.add('SUPABASE_PUBLISHABLE_KEY');
      }

      throw StateError(
        'Supabase configuration missing. '
        'Define the following via --dart-define: ${missing.join(', ')}. '
        'Example: flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...',
      );
    }

    if (!supabaseUrl.startsWith('https://') ||
        !supabaseUrl.contains('.supabase.co')) {
      throw StateError(
          'Invalid SUPABASE_URL format. Expected: https://<project>.supabase.co');
    }
  }

  // Bucket names (must match migration 003)
  static const String avatarsBucket = 'avatars';
  static const String postImagesBucket = 'post-images';
  static const String reelVideosBucket = 'reel-videos';

  // File validation constants
  static const int avatarMaxBytes = 5 * 1024 * 1024; // 5 MB
  static const int postImageMaxBytes = 10 * 1024 * 1024; // 10 MB
  static const int reelVideoMaxBytes = 100 * 1024 * 1024; // 100 MB

  static const Set<String> avatarAllowedMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  static const Set<String> postImageAllowedMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  static const Set<String> reelVideoAllowedMimeTypes = {
    'video/mp4',
    'video/quicktime',
  };

  static const Set<String> avatarAllowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  static const Set<String> postImageAllowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  static const Set<String> reelVideoAllowedExtensions = {
    '.mp4',
    '.mov',
  };

  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Username validation
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 30;
  static final RegExp usernameAllowedChars = RegExp(r'^[a-z0-9_]+$');
}
