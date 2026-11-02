import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/logger.dart';
import '../remote/auth_remote_source.dart';
import '../remote/supabase_client.dart';

final authRemoteSourceProvider = Provider<AuthRemoteSource>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRemoteSource(supabase: supabase);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteSourceProvider);
  return AuthRepository(remoteSource: remote);
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.onAuthStateChange;
});

class AuthRepository {
  AuthRepository({required AuthRemoteSource remoteSource})
      : _remoteSource = remoteSource;

  final AuthRemoteSource _remoteSource;
  bool _isGuest = false;

  bool get isGuest => _isGuest;
  void setGuest(bool val) => _isGuest = val;

  User? get currentUser => _remoteSource.currentUser;
  bool get isAuthenticated => _isGuest || currentUser != null;
  Stream<AuthState> get onAuthStateChange => _remoteSource.onAuthStateChange;

  Future<void> signInAsGuest() async {
    _isGuest = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_guest_mode', true);
  }

  Future<void> sendEmailOtp(String email) => _remoteSource.sendEmailOtp(email);

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) =>
      _remoteSource.verifyEmailOtp(email: email, token: token);

  Future<AuthResponse> signInWithGoogle() => _remoteSource.signInWithGoogle();

  Future<void> signOut() async {
    _isGuest = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('offline_guest_mode');
    } catch (_) {}
    try {
      await _remoteSource.signOut();
    } catch (e, st) {
      VaultLogger.e('Sign out error', e, st);
    }
  }
}
