import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/security/app_lock_provider.dart';
import '../../../core/security/pin_service.dart';
import '../../../l10n/app_localizations.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _canUseBiometrics = false;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final pinService = ref.read(pinServiceProvider);
    final canBio = await pinService.canUseBiometrics();
    if (mounted) {
      setState(() => _canUseBiometrics = canBio);
      if (canBio) {
        // Auto-prompt biometrics once on screen load
        _tryBiometricUnlock();
      }
    }
  }

  Future<void> _tryBiometricUnlock() async {
    final lockState = ref.read(appLockProvider);
    if (lockState.isLockedOut) return;

    final success =
        await ref.read(appLockProvider.notifier).unlockWithBiometrics();
    if (!success && mounted) {
      // Biometrics failed or cancelled, remain on PIN input
    }
  }

  Future<void> _submitPin() async {
    final l10n = AppLocalizations.of(context);
    final pin = _pinController.text.trim();
    if (pin.length < 4 || pin.length > 8) {
      setState(() => _inlineError = l10n.pinLengthError);
      return;
    }

    final success =
        await ref.read(appLockProvider.notifier).unlockWithPin(pin);
    if (!success && mounted) {
      final lockState = ref.read(appLockProvider);
      if (lockState.isLockedOut) {
        setState(() => _inlineError = null);
      } else {
        setState(() => _inlineError = l10n.pinIncorrect);
      }
      _pinController.clear();
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lockState = ref.watch(appLockProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.appName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.enterPin,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Lockout countdown banner
                if (lockState.isLockedOut) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: theme.colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            l10n.pinLockoutMessage(
                              lockState.lockoutRemainingSeconds,
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // PIN Input Field
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: TextField(
                    controller: _pinController,
                    enabled: !lockState.isLockedOut,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      letterSpacing: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••••',
                      errorText: _inlineError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _submitPin(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Unlock Button
                SizedBox(
                  width: 220,
                  height: 48,
                  child: FilledButton(
                    onPressed: lockState.isLockedOut ? null : _submitPin,
                    child: Text(l10n.unlock),
                  ),
                ),

                // Biometrics Option
                if (_canUseBiometrics && !lockState.isLockedOut) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    onPressed: _tryBiometricUnlock,
                    icon: const Icon(Icons.fingerprint_rounded, size: 24),
                    label: Text(l10n.biometricsSubtitle),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
