// lib/test/user_profile_test.dart
// Unit tests for UserProfile model and validation

import 'package:halalgram/data/model/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile', () {
    group('validateUsername', () {
      test('returns error for empty username', () {
        final error = UserProfile.validateUsername('');
        expect(error, equals('Username cannot be empty'));
      });

      test('returns error for whitespace-only username', () {
        final error = UserProfile.validateUsername('   ');
        expect(error, equals('Username cannot be empty'));
      });

      test('returns error for username too short', () {
        final error = UserProfile.validateUsername('ab');
        expect(error, equals('Username must be at least 3 characters'));
      });

      test('returns error for username too long', () {
        final longUsername = 'a' * 31;
        final error = UserProfile.validateUsername(longUsername);
        expect(error, equals('Username must be at most 30 characters'));
      });

      test('returns error for invalid characters', () {
        expect(
          UserProfile.validateUsername('user@name'),
          equals('Username can only contain letters, numbers, and underscore'),
        );
        expect(
          UserProfile.validateUsername('user-name'),
          equals('Username can only contain letters, numbers, and underscore'),
        );
        expect(
          UserProfile.validateUsername('user name'),
          equals('Username can only contain letters, numbers, and underscore'),
        );
        expect(
          UserProfile.validateUsername('user.name'),
          equals('Username can only contain letters, numbers, and underscore'),
        );
      });

      test('returns null for valid username', () {
        expect(UserProfile.validateUsername('validuser'), isNull);
        expect(UserProfile.validateUsername('user_123'), isNull);
        expect(UserProfile.validateUsername('abc'), isNull);
        expect(UserProfile.validateUsername('a' * 30), isNull);
      });

      test('trims whitespace before validation', () {
        expect(UserProfile.validateUsername('  validuser  '), isNull);
      });

      test('accepts uppercase letters (converted to lowercase)', () {
        expect(UserProfile.validateUsername('VALIDUSER'), isNull);
        expect(UserProfile.validateUsername('ValidUser'), isNull);
        expect(UserProfile.validateUsername('USER_NAME_123'), isNull);
      });

      test('rejects invalid characters regardless of case', () {
        expect(
          UserProfile.validateUsername('user@name'),
          equals('Username can only contain letters, numbers, and underscore'),
        );
        expect(
          UserProfile.validateUsername('user-name'),
          equals('Username can only contain letters, numbers, and underscore'),
        );
      });
    });

    group('validateBio', () {
      test('returns error for empty bio', () {
        final error = UserProfile.validateBio('');
        expect(error, equals('Bio cannot be empty'));
      });

      test('returns error for whitespace-only bio', () {
        final error = UserProfile.validateBio('   ');
        expect(error, equals('Bio cannot be empty'));
      });

      test('returns null for valid bio', () {
        expect(UserProfile.validateBio('Hello world'), isNull);
        expect(UserProfile.validateBio('  Hello world  '), isNull);
      });
    });

    group('fromSupabase', () {
      test('creates UserProfile from Supabase row', () {
        final map = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'username': 'testuser',
          'bio': 'Test bio',
          'avatar_path': 'user123/avatar.jpg',
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-02T00:00:00Z',
        };

        final profile = UserProfile.fromSupabase(map);

        expect(profile.id, equals('123e4567-e89b-12d3-a456-426614174000'));
        expect(profile.username, equals('testuser'));
        expect(profile.bio, equals('Test bio'));
        expect(profile.avatarPath, equals('user123/avatar.jpg'));
        expect(
            profile.createdAt, equals(DateTime.parse('2024-01-01T00:00:00Z')));
        expect(
            profile.updatedAt, equals(DateTime.parse('2024-01-02T00:00:00Z')));
      });

      test('handles null avatar_path', () {
        final map = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'username': 'testuser',
          'bio': 'Test bio',
          'avatar_path': null,
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-02T00:00:00Z',
        };

        final profile = UserProfile.fromSupabase(map);
        expect(profile.avatarPath, isNull);
      });

      test('handles missing bio', () {
        final map = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'username': 'testuser',
          'avatar_path': null,
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-02T00:00:00Z',
        };

        final profile = UserProfile.fromSupabase(map);
        expect(profile.bio, equals(''));
      });
    });
  });
}
