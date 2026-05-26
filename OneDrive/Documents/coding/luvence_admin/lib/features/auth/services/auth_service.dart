import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseConfig.client;

  /// Sign in with email and password
  static Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Sign in with Google OAuth
  /// Opens browser for Google login, then deep links back to the app
  static Future<bool> signInWithGoogle() async {
    final result = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SupabaseConfig.redirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    return result;
  }

  /// Wait for OAuth callback session
  /// Called after signInWithGoogle() — listens for the deep link to come back
  static Future<Session?> waitForOAuthSession({Duration timeout = const Duration(seconds: 120)}) async {
    // If we already have a session (came back from deep link), return it
    final existing = _client.auth.currentSession;
    if (existing != null) return existing;

    final completer = Completer<Session?>();
    StreamSubscription<AuthState>? sub;

    final timer = Timer(timeout, () {
      sub?.cancel();
      if (!completer.isCompleted) completer.complete(null);
    });

    sub = _client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        timer.cancel();
        sub?.cancel();
        if (!completer.isCompleted) completer.complete(data.session);
      }
    });

    return completer.future;
  }

  /// Sign out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get current user
  static User? get currentUser => _client.auth.currentUser;

  /// Get current session
  static Session? get currentSession => _client.auth.currentSession;

  /// Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Get user profile from profiles table
  static Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Check if user is admin/developer/owner
  static Future<bool> isAdmin() async {
    final profile = await getProfile();
    if (profile == null) return false;
    final role = profile['role'] as String?;
    return role == 'admin' || role == 'developer' || role == 'owner';
  }

  /// Get admin role string
  static Future<String> getRole() async {
    final profile = await getProfile();
    return (profile?['role'] as String?) ?? 'user';
  }

  /// Get current authenticated user's UUID (sync — from Supabase auth session)
  static Future<String?> getCurrentUserId() async {
    return currentUser?.id;
  }
}
