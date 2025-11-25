import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reading_tracker/services/auth_service.dart';

/// Provider for the AuthService singleton instance.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

/// Provider for the current authenticated user.
/// Returns null if user is not authenticated.
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((state) => state.session?.user);
});

/// Provider for checking if user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for the current user's display name.
final userDisplayNameProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return null;
      final displayName = user.userMetadata?['display_name'] as String?;
      return displayName ?? user.email?.split('@').first;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for the current user's ID.
final userIdProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.id,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for auth loading state.
final authLoadingProvider = StateProvider<bool>((ref) {
  return false;
});

/// Provider for auth error message.
final authErrorProvider = StateProvider<String?>((ref) {
  return null;
});
