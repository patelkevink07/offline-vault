import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pin_service.dart';

class AppLockState {
  const AppLockState({
    required this.isLocked,
    this.isLockedOut = false,
    this.lockoutRemainingSeconds = 0,
    this.errorMessage,
  });

  final bool isLocked;
  final bool isLockedOut;
  final int lockoutRemainingSeconds;
  final String? errorMessage;

  AppLockState copyWith({
    bool? isLocked,
    bool? isLockedOut,
    int? lockoutRemainingSeconds,
    String? errorMessage,
  }) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      isLockedOut: isLockedOut ?? this.isLockedOut,
      lockoutRemainingSeconds:
          lockoutRemainingSeconds ?? this.lockoutRemainingSeconds,
      errorMessage: errorMessage,
    );
  }
}

class AppLockNotifier extends StateNotifier<AppLockState> {
  AppLockNotifier(this._pinService)
      : super(const AppLockState(isLocked: false)) {
    checkInitialLock();
  }

  final PinService _pinService;
  Timer? _lockoutTimer;

  Future<void> checkInitialLock() async {
    final hasPin = await _pinService.hasPin();
    if (!hasPin) {
      state = const AppLockState(isLocked: false);
      return;
    }

    final lockout = await _pinService.getRemainingLockout();
    if (lockout != null && lockout.inSeconds > 0) {
      state = AppLockState(
        isLocked: true,
        isLockedOut: true,
        lockoutRemainingSeconds: lockout.inSeconds,
      );
      _startLockoutCountdown(lockout.inSeconds);
    } else {
      state = const AppLockState(isLocked: true);
    }
  }

  void _startLockoutCountdown(int seconds) {
    _lockoutTimer?.cancel();
    var remaining = seconds;
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(
          isLockedOut: false,
          lockoutRemainingSeconds: 0,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isLockedOut: true,
          lockoutRemainingSeconds: remaining,
        );
      }
    });
  }

  Future<bool> unlockWithPin(String pin) async {
    final result = await _pinService.verifyPin(pin);
    if (result.success) {
      _lockoutTimer?.cancel();
      state = const AppLockState(isLocked: false);
      return true;
    } else {
      if (result.isLockedOut && result.remainingLockout != null) {
        final sec = result.remainingLockout!.inSeconds;
        state = state.copyWith(
          isLocked: true,
          isLockedOut: true,
          lockoutRemainingSeconds: sec,
          errorMessage: result.errorMessage,
        );
        _startLockoutCountdown(sec);
      } else {
        state = state.copyWith(
          isLocked: true,
          errorMessage: result.errorMessage,
        );
      }
      return false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    final success = await _pinService.authenticateWithBiometrics();
    if (success) {
      _lockoutTimer?.cancel();
      state = const AppLockState(isLocked: false);
      return true;
    }
    return false;
  }

  void lockApp() {
    _pinService.hasPin().then((hasPin) {
      if (hasPin) {
        state = state.copyWith(isLocked: true);
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }
}

final appLockProvider =
    StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  final pinService = ref.watch(pinServiceProvider);
  return AppLockNotifier(pinService);
});
