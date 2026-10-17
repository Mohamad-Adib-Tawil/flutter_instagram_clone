// lib/data/model/user_profile.dart
// Application-level user profile model (backend-neutral)

import 'package:halalgram/core/config/supabase_config.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.bio,
    this.avatarPath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String username;
  final String bio;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Creates UserProfile from Supabase profiles table row
  factory UserProfile.fromSupabase(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      username: map['username'] as String,
      bio: map['bio'] as String? ?? '',
      avatarPath: map['avatar_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Gets the public avatar URL (resolves at presentation boundary)
  String? get avatarUrl {
    if (avatarPath == null || avatarPath!.isEmpty) {
      return null;
    }
    // This will be resolved by the UI layer using SupabaseProfileService
    return avatarPath;
  }

  /// Validates username according to SupabaseConfig rules
  static String? validateUsername(String username) {
    final trimmed = username.trim();

    if (trimmed.isEmpty) {
      return 'Username cannot be empty';
    }
    if (trimmed.length < SupabaseConfig.usernameMinLength) {
      return 'Username must be at least ${SupabaseConfig.usernameMinLength} characters';
    }
    if (trimmed.length > SupabaseConfig.usernameMaxLength) {
      return 'Username must be at most ${SupabaseConfig.usernameMaxLength} characters';
    }
    if (!SupabaseConfig.usernameAllowedChars.hasMatch(trimmed.toLowerCase())) {
      return 'Username can only contain letters, numbers, and underscore';
    }
    return null;
  }

  /// Validates bio
  static String? validateBio(String bio) {
    if (bio.trim().isEmpty) {
      return 'Bio cannot be empty';
    }
    return null;
  }
}
