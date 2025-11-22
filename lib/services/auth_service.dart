import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reading_tracker/services/supabase_service.dart';

/// Result class for authentication operations.
class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });

  factory AuthResult.success(User? user) {
    return AuthResult(success: true, user: user);
  }

  factory AuthResult.failure(String message) {
    return AuthResult(success: false, errorMessage: message);
  }
}

/// Service for managing authentication with Supabase.
class AuthService extends ChangeNotifier {
  static AuthService? _instance;

  User? _currentUser;
  bool _isLoading = false;
  StreamSubscription<AuthState>? _authSubscription;

  AuthService._() {
    _initialize();
  }

  /// Get singleton instance.
  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  /// Initialize auth state listener.
  void _initialize() {
    try {
      _currentUser = SupabaseService.client.auth.currentUser;
      _authSubscription = SupabaseService.authStateChanges.listen((state) {
        _currentUser = state.session?.user;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('AuthService initialization error: $e');
    }
  }

  /// Get the Supabase client.
  static SupabaseClient get _client => SupabaseService.client;

  /// Current authenticated user.
  User? get currentUser => _currentUser;

  /// Current user ID.
  String? get userId => _currentUser?.id;

  /// Current user email.
  String? get userEmail => _currentUser?.email;

  /// Check if user is authenticated.
  bool get isAuthenticated => _currentUser != null;

  /// Check if loading.
  bool get isLoading => _isLoading;

  /// Auth state changes stream.
  Stream<AuthState> get authStateChanges => SupabaseService.authStateChanges;

  // ============ SIGN UP ============

  /// Sign up with email and password.
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _setLoading(true);

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );

      if (response.user == null) {
        return AuthResult.failure('Sign up failed. Please try again.');
      }

      // Check if email confirmation is required
      if (response.user!.identities?.isEmpty ?? true) {
        return AuthResult.failure(
          'An account with this email already exists.',
        );
      }

      _currentUser = response.user;
      notifyListeners();

      return AuthResult.success(response.user);
    } on AuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ============ SIGN IN ============

  /// Sign in with email and password.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult.failure('Sign in failed. Please try again.');
      }

      _currentUser = response.user;
      notifyListeners();

      return AuthResult.success(response.user);
    } on AuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with magic link (passwordless).
  Future<AuthResult> signInWithMagicLink({required String email}) async {
    try {
      _setLoading(true);

      await _client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: kIsWeb ? null : 'io.supabase.readingtracker://login-callback/',
      );

      return AuthResult.success(null);
    } on AuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ============ SIGN OUT ============

  /// Sign out the current user.
  Future<AuthResult> signOut() async {
    try {
      _setLoading(true);

      await _client.auth.signOut();
      _currentUser = null;
      notifyListeners();

      return AuthResult.success(null);
    } on AuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ============ PASSWORD RESET ============

  /// Send password reset email.
  Future<AuthResult> sendPasswordResetEmail({required String email}) async {
    try {
      _setLoading(true);

      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : 'io.supabase.readingtracker://reset-callback/',
      );

      return AuthResult.success(null);
    } on AuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update user password.
  Future<AuthResult> updatePassword({required String newPassword}) async {
    try {
      _setLoading(true);

      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return AuthResult.success(response.user);
    } on AuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ============ USER PROFILE ============

  /// Update user display name.
  Future<AuthResult> updateDisplayName({required String displayName}) async {
    try {
      _setLoading(true);

      final response = await _client.auth.updateUser(
        UserAttributes(data: {'display_name': displayName}),
      );

      _currentUser = response.user;
      notifyListeners();

      return AuthResult.success(response.user);
    } on AuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get user display name.
  String? get displayName {
    return _currentUser?.userMetadata?['display_name'] as String?;
  }

  // ============ HELPERS ============

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Convert AuthException to user-friendly message.
  String _getAuthErrorMessage(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please verify your email address.';
    }
    if (message.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('password')) {
      return 'Password must be at least 6 characters.';
    }
    if (message.contains('email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('rate limit')) {
      return 'Too many attempts. Please try again later.';
    }

    return e.message;
  }

  /// Dispose resources.
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
