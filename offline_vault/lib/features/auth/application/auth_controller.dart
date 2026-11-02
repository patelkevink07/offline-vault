import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/env_config.dart';
import '../../../core/utils/logger.dart';
import '../../../data/repositories/auth_repository.dart';

sealed class AuthStateData {
  const AuthStateData();
}

class AuthInitial extends AuthStateData {
  const AuthInitial();
}

class AuthLoading extends AuthStateData {
  const AuthLoading();
}

class AuthOtpSent extends AuthStateData {
  const AuthOtpSent({required this.email, this.errorMessage});
  final String email;
  final String? errorMessage;
}

class AuthAuthenticated extends AuthStateData {
  const AuthAuthenticated();
}

class AuthError extends AuthStateData {
  const AuthError({required this.message});
  final String message;
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthStateData>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository: repository);
});

class AuthController extends StateNotifier<AuthStateData> {
  AuthController({required AuthRepository repository})
      : _repository = repository,
        super(
          repository.isAuthenticated
              ? const AuthAuthenticated()
              : const AuthInitial(),
        );

  final AuthRepository _repository;

  Future<void> signInWithGoogle() async {
    if (EnvConfig.googleWebClientId.isEmpty) {
      state = const AuthError(
        message:
            'Google OAuth is not configured yet. Sign in with Email OTP above or tap "Offline Vault Mode" below.',
      );
      return;
    }
    state = const AuthLoading();
    try {
      await _repository.signInWithGoogle();
      state = const AuthAuthenticated();
    } catch (e, st) {
      VaultLogger.e('Google sign-in failed', e, st);
      final errorStr = e.toString();
      if (errorStr.contains('10') || errorStr.contains('DEVELOPER_ERROR')) {
        state = const AuthError(
          message:
              'Google Sign-In is not configured for this APK build (missing SHA-1 in Google Cloud Console). Tap "Offline Vault Mode" below to proceed.',
        );
      } else if (errorStr.contains('cancelled by user') ||
          errorStr.contains('sign-in was cancelled')) {
        state = const AuthInitial();
      } else {
        state = AuthError(message: 'Sign-in failed: $e');
      }
    }
  }

  Future<void> continueAsGuest() async {
    state = const AuthLoading();
    try {
      await _repository.signInAsGuest();
      state = const AuthAuthenticated();
    } catch (e, st) {
      VaultLogger.e('Guest sign-in failed', e, st);
      state = AuthError(message: e.toString());
    }
  }

  Future<void> sendEmailOtp(String email) async {
    state = const AuthLoading();
    try {
      await _repository.sendEmailOtp(email);
      state = AuthOtpSent(email: email.trim());
    } catch (e, st) {
      VaultLogger.e('Send email OTP failed', e, st);
      state = AuthError(message: e.toString());
    }
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    state = const AuthLoading();
    try {
      await _repository.verifyEmailOtp(email: email, token: token);
      state = const AuthAuthenticated();
    } catch (e, st) {
      VaultLogger.e('Verify OTP failed', e, st);
      final rawErr = e.toString().toLowerCase();
      String userMessage = 'Invalid or expired OTP code. Please check your email or tap "Resend Code".';
      if (rawErr.contains('network') || rawErr.contains('socket')) {
        userMessage = 'Network error. Please check your connection or use Offline Vault Mode.';
      }
      state = AuthOtpSent(email: email, errorMessage: userMessage);
    }
  }

  void resetToInitial() {
    state = const AuthInitial();
  }

  Future<void> signOut() async {
    state = const AuthLoading();
    await _repository.signOut();
    state = const AuthInitial();
  }
}
