// lib/core/database/supabase_client.dart
// Typed Supabase client accessor

import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides access to the initialized Supabase client.
/// Use this instead of `Supabase.instance.client` directly for testability.
class SupabaseDatabase {
  SupabaseDatabase._();

  static SupabaseClient get client => Supabase.instance.client;

  /// Convenience getters for common table references
  static SupabaseQueryBuilder get profiles => client.from('profiles');
  static SupabaseQueryBuilder get posts => client.from('posts');
  static SupabaseQueryBuilder get reels => client.from('reels');
  static SupabaseQueryBuilder get postLikes => client.from('post_likes');
  static SupabaseQueryBuilder get reelLikes => client.from('reel_likes');
  static SupabaseQueryBuilder get postComments => client.from('post_comments');
  static SupabaseQueryBuilder get reelComments => client.from('reel_comments');
  static SupabaseQueryBuilder get follows => client.from('follows');

  /// Storage bucket references (returns StorageFileApi for bucket operations)
  static StorageFileApi get avatarsStorage => client.storage.from('avatars');
  static StorageFileApi get postImagesStorage =>
      client.storage.from('post-images');
  static StorageFileApi get reelVideosStorage =>
      client.storage.from('reel-videos');
}
