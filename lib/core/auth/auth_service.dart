// lib/core/auth/auth_service.dart
// Application-level authentication abstraction backed by Supabase

import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication session state
enum AuthSessionState {
  authenticated,
  unauthenticated,
  loading,
}

/// Result of authentication operations
class AuthResult {
  final bool success;
  final String? errorMessage;
  final bool emailConfirmationRequired;

  const AuthResult._({
    required this.success,
    this.errorMessage,
    this.emailConfirmationRequired = false,
  });

  factory AuthResult.success({bool emailConfirmationRequired = false}) =>
      _AuthSuccess(emailConfirmationRequired: emailConfirmationRequired);
  factory AuthResult.failure(String message) => _AuthFailure(message);
}

class _AuthSuccess extends AuthResult {
  const _AuthSuccess({bool emailConfirmationRequired = false})
      : super._(
            success: true,
            emailConfirmationRequired: emailConfirmationRequired);
}

class _AuthFailure extends AuthResult {
  const _AuthFailure(String message)
      : super._(success: false, errorMessage: message);
}

/// Centralized authentication service using Supabase Auth
class AuthService {
  AuthService._();

  static final AuthService _instance = AuthService._();

  static AuthService get instance => _instance;

  SupabaseClient get _client => Supabase.instance.client;

  GoTrueClient get _auth => _client.auth;

  /// Current user ID (null if not authenticated)
  String? get currentUserId => _auth.currentUser?.id;

  /// Whether a user is currently authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Current session (null if not authenticated)
  Session? get currentSession => _auth.currentSession;

  /// Stream of authentication state changes
  Stream<AuthSessionState> get authStateChanges {
    return _auth.onAuthStateChange.map((event) {
      final session = event.session;
      if (session != null) {
        return AuthSessionState.authenticated;
      }
      return AuthSessionState.unauthenticated;
    });
  }

  /// Stream of raw Supabase auth events (for advanced use cases)
  Stream<AuthState> get rawAuthStateChanges => _auth.onAuthStateChange;

  /// Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        return AuthResult.success();
      }

      // Check if email confirmation is required
      if (response.session == null && response.user != null) {
        return AuthResult.success(emailConfirmationRequired: true);
      }

      return AuthResult.failure('Sign in failed. Please try again.');
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthException(e));
    } catch (e) {
      return AuthResult.failure(_mapGenericError(e));
    }
  }

  /// Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: metadata,
      );

      if (response.user != null) {
        if (response.session != null) {
          return AuthResult.success();
        } else {
          // Email confirmation required
          return AuthResult.success(emailConfirmationRequired: true);
        }
      }

      return AuthResult.failure('Sign up failed. Please try again.');
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthException(e));
    } catch (e) {
      return AuthResult.failure(_mapGenericError(e));
    }
  }

  /// Sign out the current user
  Future<AuthResult> signOut() async {
    try {
      await _auth.signOut();
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthException(e));
    } catch (e) {
      return AuthResult.failure('Failed to sign out. Please try again.');
    }
  }

  /// Request a password reset email
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: _getPasswordResetRedirectUrl(),
      );
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthException(e));
    } catch (e) {
      return AuthResult.failure(
          'Failed to send reset email. Please try again.');
    }
  }

  /// Update user metadata (e.g., username during signup)
  Future<AuthResult> updateUserMetadata(Map<String, dynamic> metadata) async {
    try {
      await _auth.updateUser(UserAttributes(data: metadata));
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthException(e));
    } catch (e) {
      return AuthResult.failure('Failed to update profile. Please try again.');
    }
  }

  /// Get the current user's email
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Get the current user's metadata
  Map<String, dynamic>? get currentUserMetadata =>
      _auth.currentUser?.userMetadata;

  String _getPasswordResetRedirectUrl() {
    // For mobile apps, we typically don't need a redirect URL
    // The user opens the link in the browser and the app handles it via deep links
    // Configure this in Supabase Dashboard: Authentication > URL Configuration
    return 'io.supabase.flutter://password-reset';
  }

  String _mapAuthException(AuthException e) {
    final code = e.code;
    final message = e.message;

    switch (code) {
      case 'invalid_credentials':
      case 'invalid_email_or_password':
        return 'Invalid email or password. Please try again.';
      case 'email_not_confirmed':
        return 'Please verify your email address before signing in.';
      case 'user_not_found':
        return 'No account found with this email.';
      case 'weak_password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'email_already_exists':
      case 'user_already_exists':
        return 'An account with this email already exists.';
      case 'invalid_email':
        return 'Invalid email format. Please check your email.';
      case 'too_many_requests':
        return 'Too many attempts. Please try again later.';
      case 'network_error':
        return 'Network error. Please check your connection and try again.';
      case 'signup_disabled':
        return 'Sign up is currently disabled.';
      default:
        // Don't expose internal error details
        return message.isNotEmpty
            ? message
            : 'Authentication failed. Please try again.';
    }
  }

  String _mapGenericError(dynamic e) {
    final message = e.toString().toLowerCase();
    if (message.contains('network') || message.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (message.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
