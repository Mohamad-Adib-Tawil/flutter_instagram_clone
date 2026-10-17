// lib/data/supabase_service/supabase_posts.dart
// Supabase posts service with image upload and pagination

import 'dart:io';

import 'package:flutter_instagram_clone/core/config/supabase_config.dart';
import 'package:flutter_instagram_clone/core/database/supabase_client.dart';
import 'package:flutter_instagram_clone/data/model/post.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabasePostsService {
  SupabasePostsService._();

  static final SupabasePostsService _instance = SupabasePostsService._();

  static SupabasePostsService get instance => _instance;

  final _uuid = const Uuid();
  static const int _defaultPageSize = 20;

  /// Create a new post with image upload
  /// Returns the created Post on success
  Future<Post> createPost({
    required File imageFile,
    required String caption,
    required String location,
  }) async {
    final userId = SupabaseDatabase.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('No authenticated user');
    }

    // Validate image
    final validationError = _validatePostImage(imageFile);
    if (validationError != null) {
      throw Exception(validationError);
    }

    // Generate post ID upfront for storage path
    final postId = _uuid.v4();
    final imagePath = await _uploadPostImage(userId, postId, imageFile);

    try {
      // Insert post into database
      final postMap = {
        'id': postId,
        'user_id': userId,
        'image_path': imagePath,
        'caption': caption.trim(),
        'location': location.trim(),
      };

      await SupabaseDatabase.posts.insert(postMap);

      // Fetch the created post with author
      return await _fetchPostWithAuthor(postId);
    } catch (e) {
      // Cleanup: attempt to delete uploaded image on DB failure
      await _cleanupPostImage(imagePath);
      throw Exception('Failed to create post: $e');
    }
  }

  /// Upload post image to Supabase Storage
  Future<String> _uploadPostImage(
      String userId, String postId, File file) async {
    final fileExt = p.extension(file.path).toLowerCase();
    final fileName = '${_uuid.v4()}$fileExt';
    final objectPath = '$userId/$postId/$fileName';

    await SupabaseDatabase.postImagesStorage.upload(
      objectPath,
      file,
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: false,
      ),
    );

    return objectPath;
  }

  /// Cleanup uploaded image on failure
  Future<void> _cleanupPostImage(String objectPath) async {
    try {
      await SupabaseDatabase.postImagesStorage.remove([objectPath]);
    } catch (_) {
      // Log but don't throw - cleanup is best effort
    }
  }

  /// Validate post image file
  String? _validatePostImage(File file) {
    if (!file.existsSync()) {
      return 'File does not exist';
    }

    final size = file.lengthSync();
    if (size > SupabaseConfig.postImageMaxBytes) {
      return 'File size exceeds 10 MB limit';
    }

    final ext = p.extension(file.path).toLowerCase();
    if (!SupabaseConfig.postImageAllowedExtensions.contains(ext)) {
      return 'Unsupported file format. Use JPG, PNG, or WebP.';
    }

    return null;
  }

  /// Fetch a single post with author by ID
  Future<Post> _fetchPostWithAuthor(String postId) async {
    final response = await SupabaseDatabase.posts
        .select('*, profiles!posts_user_id_fkey(*)')
        .eq('id', postId)
        .single();

    final postMap = Map<String, dynamic>.from(response);
    final authorMap = Map<String, dynamic>.from(postMap.remove('profiles'));

    return Post.fromSupabase(
      postMap: postMap,
      authorMap: authorMap,
    );
  }

  /// Get paginated feed (global - all posts newest first)
  /// Uses simple timestamp-based pagination (fetches older posts than cursor)
  Future<PostPage> getFeed({
    PostCursor? cursor,
    int limit = _defaultPageSize,
  }) async {
    final effectiveLimit = limit.clamp(1, SupabaseConfig.maxPageSize);

    var query =
        SupabaseDatabase.posts.select('*, profiles!posts_user_id_fkey(*)');

    if (cursor != null) {
      // Apply filter before order/limit to avoid PostgrestTransformBuilder issue
      query = query.lt('created_at', cursor.createdAt.toIso8601String());
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(effectiveLimit + 1); // Fetch one extra to detect hasMore

    final items = (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final hasMore = items.length > effectiveLimit;
    final feedItems = hasMore ? items.sublist(0, effectiveLimit) : items;

    PostCursor? nextCursor;
    if (hasMore && feedItems.isNotEmpty) {
      final lastPost = feedItems.last;
      nextCursor = PostCursor(
        createdAt: DateTime.parse(lastPost['created_at'] as String),
        id: lastPost['id'] as String,
      );
    }

    final posts = feedItems.map((map) {
      final postMap = Map<String, dynamic>.from(map);
      final authorMap = Map<String, dynamic>.from(postMap.remove('profiles'));
      return Post.fromSupabase(postMap: postMap, authorMap: authorMap);
    }).toList();

    return PostPage(
      posts: posts,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  /// Get paginated posts for a specific user (profile grid)
  Future<PostPage> getUserPosts({
    required String userId,
    PostCursor? cursor,
    int limit = _defaultPageSize,
  }) async {
    final effectiveLimit = limit.clamp(1, SupabaseConfig.maxPageSize);

    var query = SupabaseDatabase.posts
        .select('*, profiles!posts_user_id_fkey(*)')
        .eq('user_id', userId);

    if (cursor != null) {
      query = query.lt('created_at', cursor.createdAt.toIso8601String());
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(effectiveLimit + 1);

    final items = (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final hasMore = items.length > effectiveLimit;
    final feedItems = hasMore ? items.sublist(0, effectiveLimit) : items;

    PostCursor? nextCursor;
    if (hasMore && feedItems.isNotEmpty) {
      final lastPost = feedItems.last;
      nextCursor = PostCursor(
        createdAt: DateTime.parse(lastPost['created_at'] as String),
        id: lastPost['id'] as String,
      );
    }

    final posts = feedItems.map((map) {
      final postMap = Map<String, dynamic>.from(map);
      final authorMap = Map<String, dynamic>.from(postMap.remove('profiles'));
      return Post.fromSupabase(postMap: postMap, authorMap: authorMap);
    }).toList();

    return PostPage(
      posts: posts,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  /// Get paginated posts for Explore (same as feed for now)
  Future<PostPage> getExplorePosts({
    PostCursor? cursor,
    int limit = _defaultPageSize,
  }) async {
    return getFeed(cursor: cursor, limit: limit);
  }

  /// Get public URL for post image
  String getPostImageUrl(String imagePath) {
    return SupabaseDatabase.postImagesStorage.getPublicUrl(imagePath);
  }

  /// Delete a post (and its image)
  Future<void> deletePost(String postId) async {
    final userId = SupabaseDatabase.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('No authenticated user');
    }

    // First get the post to find image path
    final post = await SupabaseDatabase.posts
        .select('image_path')
        .eq('id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (post == null) {
      throw Exception('Post not found or not owned by user');
    }

    final imagePath = post['image_path'] as String;

    // Delete from database (RLS ensures ownership)
    await SupabaseDatabase.posts
        .delete()
        .eq('id', postId)
        .eq('user_id', userId);

    // Cleanup storage object
    await SupabaseDatabase.postImagesStorage.remove([imagePath]);
  }
}
