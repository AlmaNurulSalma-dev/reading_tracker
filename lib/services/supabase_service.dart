import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for managing Supabase client initialization and access.
class SupabaseService {
  static SupabaseClient? _client;

  /// Private constructor to prevent instantiation
  SupabaseService._();

  /// Initialize Supabase with environment variables.
  /// Call this in main() before runApp().
  static Future<void> initialize() async {
    // Load environment variables
    await dotenv.load(fileName: '.env');

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw Exception(
        'SUPABASE_URL is not set. Please check your .env file.',
      );
    }

    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY is not set. Please check your .env file.',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );

    _client = Supabase.instance.client;
  }

  /// Get the Supabase client instance.
  /// Throws if [initialize] hasn't been called.
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'SupabaseService not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  /// Get the current authenticated user, if any.
  static User? get currentUser => client.auth.currentUser;

  /// Check if a user is currently authenticated.
  static bool get isAuthenticated => currentUser != null;

  /// Get the auth state change stream.
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Sign out the current user.
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
