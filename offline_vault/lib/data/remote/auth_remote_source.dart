import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/logger.dart';

/// Remote authentication data source using Supabase Auth.
class AuthRemoteSource {
  AuthRemoteSource({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  /// Send 6-digit OTP code to email.
  Future<void> sendEmailOtp(String email) async {
    VaultLogger.i('Sending email OTP...');
    await _supabase.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: true,
    );
  }

  /// Verify 6-digit OTP code for email.
  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    VaultLogger.i('Verifying email OTP...');
    return _supabase.auth.verifyOTP(
      type: OtpType.email,
      email: email.trim(),
      token: token.trim(),
    );
  }

  /// Sign in using Google OAuth (Android native via google_sign_in + Supabase idToken).
  Future<AuthResponse> signInWithGoogle() async {
    VaultLogger.i('Initiating Google Sign-In...');
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google sign-in was cancelled by user.');
    }
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const AuthException('Failed to retrieve ID token from Google.');
    }

    return _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// Sign out current user.
  Future<void> signOut() async {
    VaultLogger.i('Signing out...');
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
    await _supabase.auth.signOut();
  }
}
