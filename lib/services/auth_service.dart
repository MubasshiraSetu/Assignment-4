import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // ─── Current session ────────────────────────────────────────
  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  // ─── Register ───────────────────────────────────────────────
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );

      if (response.user == null) {
        return AuthResult.error('Registration failed. Please try again.');
      }

      // Insert extra profile data
      if (phone != null && phone.trim().isNotEmpty) {
        await _supabase.from('profiles').upsert({
          'id': response.user!.id,
          'full_name': fullName.trim(),
          'phone': phone.trim(),
        });
      }

      return AuthResult.success(
        message: 'Account created! Please check your email to verify.',
      );
    } on AuthException catch (e) {
      return AuthResult.error(_friendlyAuthError(e.message));
    } catch (e) {
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  // ─── Login ──────────────────────────────────────────────────
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        return AuthResult.error('Login failed. Please check your credentials.');
      }

      return AuthResult.success(message: 'Welcome back!');
    } on AuthException catch (e) {
      return AuthResult.error(_friendlyAuthError(e.message));
    } catch (e) {
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  // ─── Logout ─────────────────────────────────────────────────
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // ─── Fetch profile ──────────────────────────────────────────
  Future<UserProfile?> fetchProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromMap(data, user.email ?? '');
    } catch (_) {
      return null;
    }
  }

  // ─── Reset password ─────────────────────────────────────────
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      return AuthResult.success(message: 'Password reset email sent!');
    } on AuthException catch (e) {
      return AuthResult.error(_friendlyAuthError(e.message));
    } catch (_) {
      return AuthResult.error('Failed to send reset email.');
    }
  }

  // ─── Error messages ─────────────────────────────────────────
  String _friendlyAuthError(String raw) {
    if (raw.contains('already registered') || raw.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('Invalid login credentials') || raw.contains('invalid_credentials')) {
      return 'Incorrect email or password.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    if (raw.contains('Password should be')) {
      return 'Password must be at least 6 characters.';
    }
    if (raw.contains('rate limit')) {
      return 'Too many attempts. Please wait and try again.';
    }
    return raw;
  }
}

// ─── Result wrapper ──────────────────────────────────────────
class AuthResult {
  final bool success;
  final String message;

  AuthResult._({required this.success, required this.message});

  factory AuthResult.success({required String message}) =>
      AuthResult._(success: true, message: message);

  factory AuthResult.error(String message) =>
      AuthResult._(success: false, message: message);
}
