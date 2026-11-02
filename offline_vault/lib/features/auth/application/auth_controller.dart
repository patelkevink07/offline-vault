import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  const AuthOtpSent({required this.email});
  final String email;
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
    state = const AuthLoading();
    try {
      await _repository.signInWithGoogle();
      state = const AuthAuthenticated();
    } catch (e, st) {
      VaultLogger.e('Google sign-in failed', e, st);
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
      state = AuthError(message: e.toString());
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
