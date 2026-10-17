// lib/data/supabase_service/supabase_profile.dart
// Supabase profile and avatar management

import 'dart:io';

import 'package:flutter_instagram_clone/core/config/supabase_config.dart';
import 'package:flutter_instagram_clone/core/database/supabase_client.dart';
import 'package:flutter_instagram_clone/data/model/user_profile.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseProfileService {
  SupabaseProfileService._();

  static final SupabaseProfileService _instance = SupabaseProfileService._();

  static SupabaseProfileService get instance => _instance;

  final _uuid = const Uuid();

  /// Upload avatar to Supabase Storage
  /// Returns the storage object path on success
  Future<String?> uploadAvatar(File file) async {
    try {
      // Validate file
      final validationError = _validateAvatarFile(file);
      if (validationError != null) {
        throw Exception(validationError);
      }

      final userId = SupabaseDatabase.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      final fileExt = p.extension(file.path).toLowerCase();
      final fileName = '${_uuid.v4()}$fileExt';
      final objectPath = '$userId/$fileName';

      // Upload to avatars bucket
      await SupabaseDatabase.avatarsStorage.upload(
        objectPath,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      return objectPath;
    } on StorageException catch (e) {
      throw Exception('Avatar upload failed: ${e.message}');
    } catch (e) {
      throw Exception('Avatar upload failed: $e');
    }
  }

  /// Get public URL for avatar
  String getAvatarPublicUrl(String objectPath) {
    return SupabaseDatabase.avatarsStorage.getPublicUrl(objectPath);
  }

  /// Update profile avatar path
  Future<void> updateAvatarPath(String objectPath) async {
    try {
      await SupabaseDatabase.profiles.update({'avatar_path': objectPath}).eq(
          'id', SupabaseDatabase.client.auth.currentUser!.id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update avatar: ${e.message}');
    }
  }

  /// Get current user's profile as typed model
  Future<UserProfile?> getCurrentProfile() async {
    final userId = SupabaseDatabase.client.auth.currentUser?.id;
    if (userId == null) return null;
    return getProfile(userId);
  }

  /// Get any user's profile by ID
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final response =
          await SupabaseDatabase.profiles.select().eq('id', userId).single();

      return UserProfile.fromSupabase(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // No rows found
        return null;
      }
      throw Exception('Failed to fetch profile: ${e.message}');
    }
  }

  /// Search users by username prefix (case-insensitive)
  /// Returns up to [limit] results
  Future<List<UserProfile>> searchUsers(String query, {int limit = 20}) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    try {
      // Use ILIKE for case-insensitive prefix search on citext column
      final response = await SupabaseDatabase.profiles
          .select()
          .ilike('username', '$trimmed%')
          .limit(limit);

      return response.map((map) => UserProfile.fromSupabase(map)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to search users: ${e.message}');
    }
  }

  /// Update profile fields (bio, username)
  Future<void> updateProfile({
    String? username,
    String? bio,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (bio != null) updates['bio'] = bio;

      if (updates.isEmpty) return;

      await SupabaseDatabase.profiles
          .update(updates)
          .eq('id', SupabaseDatabase.client.auth.currentUser!.id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update profile: ${e.message}');
    }
  }

  /// Validate avatar file before upload
  String? _validateAvatarFile(File file) {
    // Check file exists
    if (!file.existsSync()) {
      return 'File does not exist';
    }

    // Check file size
    final size = file.lengthSync();
    if (size > SupabaseConfig.avatarMaxBytes) {
      return 'File size exceeds 5 MB limit';
    }

    // Check extension
    final ext = p.extension(file.path).toLowerCase();
    if (!SupabaseConfig.avatarAllowedExtensions.contains(ext)) {
      return 'Unsupported file format. Use JPG, PNG, or WebP.';
    }

    return null;
  }
}
