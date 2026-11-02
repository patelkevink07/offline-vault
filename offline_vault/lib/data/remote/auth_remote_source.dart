import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/env_config.dart';
import '../../core/utils/logger.dart';

/// Remote authentication data source using Supabase Auth.
class AuthRemoteSource {
  AuthRemoteSource({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  User? get currentUser {
    try {
      return _supabase.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Session? get currentSession {
    try {
      return _supabase.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  Stream<AuthState> get onAuthStateChange {
    try {
      return _supabase.auth.onAuthStateChange;
    } catch (_) {
      return const Stream.empty();
    }
  }

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
    final trimmedEmail = email.trim();
    final trimmedToken = token.trim();
    try {
      return await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: trimmedEmail,
        token: trimmedToken,
      );
    } catch (e) {
      VaultLogger.w('verifyOTP with OtpType.email failed ($e), trying OtpType.signup...');
      try {
        return await _supabase.auth.verifyOTP(
          type: OtpType.signup,
          email: trimmedEmail,
          token: trimmedToken,
        );
      } catch (e2) {
        VaultLogger.w('verifyOTP with OtpType.signup failed ($e2), trying OtpType.magiclink...');
        return await _supabase.auth.verifyOTP(
          type: OtpType.magiclink,
          email: trimmedEmail,
          token: trimmedToken,
        );
      }
    }
  }

  /// Sign in using Google OAuth (Android native via google_sign_in + Supabase idToken).
  Future<AuthResponse> signInWithGoogle() async {
    VaultLogger.i('Initiating Google Sign-In...');
    final googleSignIn = GoogleSignIn(
      serverClientId: EnvConfig.googleWebClientId.isNotEmpty
          ? EnvConfig.googleWebClientId
          : null,
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
