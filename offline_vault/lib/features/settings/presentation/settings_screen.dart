import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/security/pin_service.dart';
import '../../../core/storage/secure_prefs.dart';
import '../../../core/utils/battery_optimization_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _wifiOnly = true;
  bool _blockScreenshots = false;
  bool _hasPin = false;
  bool _biometricsEnabled = false;
  bool _canUseBiometrics = false;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = ref.read(securePrefsProvider);
    final pinService = ref.read(pinServiceProvider);

    final wifi = await prefs.getSyncOnWifiOnly();
    final block = await prefs.getBlockScreenshots();
    final pin = await pinService.hasPin();
    final bioEnabled = await prefs.getBiometricsEnabled();
    final canBio = await pinService.canUseBiometrics();
    final lang = await prefs.getLanguageCode() ?? 'en';

    if (mounted) {
      setState(() {
        _wifiOnly = wifi;
        _blockScreenshots = block;
        _hasPin = pin;
        _biometricsEnabled = bioEnabled;
        _canUseBiometrics = canBio;
        _language = lang;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.read(securePrefsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // Sync Section
          _buildSectionHeader(l10n.syncAndNetwork),
          SwitchListTile(
            title: Text(l10n.syncWifiOnly),
            subtitle: Text(l10n.syncWifiOnlySubtitle),
            value: _wifiOnly,
            onChanged: (val) async {
              setState(() => _wifiOnly = val);
              await prefs.setSyncOnWifiOnly(val);
            },
          ),
          ListTile(
            leading: const Icon(Icons.battery_saver_rounded),
            title: Text(l10n.batteryOptimization),
            subtitle: Text(l10n.batteryOptimizationSubtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => BatteryOptimizationHelper.showGuideDialog(context),
          ),
          const Divider(),

          // Security Section
          _buildSectionHeader(l10n.privacyAndSecurity),
          SwitchListTile(
            title: Text(l10n.blockScreenshots),
            subtitle: Text(l10n.blockScreenshotsSubtitle),
            value: _blockScreenshots,
            onChanged: (val) async {
              setState(() => _blockScreenshots = val);
              await prefs.setBlockScreenshots(val);
            },
          ),
          ListTile(
            title: Text(l10n.settingsAppLockTitle),
            subtitle: Text(
              _hasPin
                  ? l10n.settingsAppLockSubtitleSet
                  : l10n.settingsAppLockSubtitleNotSet,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _hasPin ? _showPinOptionsSheet : _showSetPinDialog,
          ),
          if (_hasPin && _canUseBiometrics)
            SwitchListTile(
              title: Text(l10n.biometricsEnabled),
              subtitle: Text(l10n.biometricsSubtitle),
              value: _biometricsEnabled,
              onChanged: (val) async {
                setState(() => _biometricsEnabled = val);
                await ref.read(pinServiceProvider).setBiometricsEnabled(val);
              },
            ),
          const Divider(),

          // Storage Section
          _buildSectionHeader(l10n.storage),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: Text(l10n.freeUpSpace),
            subtitle: Text(l10n.freeUpSpaceSubtitle),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.spaceCleared)),
              );
            },
          ),
          const Divider(),

          // Language Section
          _buildSectionHeader(l10n.language),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'en',
            groupValue: _language,
            onChanged: (val) async {
              if (val == null) return;
              setState(() => _language = val);
              await prefs.setLanguageCode(val);
            },
          ),
          RadioListTile<String>(
            title: const Text('ગુજરાતી (Gujarati)'),
            value: 'gu',
            groupValue: _language,
            onChanged: (val) async {
              if (val == null) return;
              setState(() => _language = val);
              await prefs.setLanguageCode(val);
            },
          ),
          RadioListTile<String>(
            title: const Text('हिन्दी (Hindi)'),
            value: 'hi',
            groupValue: _language,
            onChanged: (val) async {
              if (val == null) return;
              setState(() => _language = val);
              await prefs.setLanguageCode(val);
            },
          ),
          const Divider(),

          // Account Section
          _buildSectionHeader(l10n.account),
          ListTile(
            leading:
                const Icon(Icons.logout_rounded, color: AppColors.lightError),
            title: Text(
              l10n.signOut,
              style: const TextStyle(color: AppColors.lightError),
            ),
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showPinOptionsSheet() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.password_rounded),
                title: Text(l10n.settingsChangePin),
                onTap: () {
                  Navigator.pop(ctx);
                  _showChangePinDialog();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.lightError),
                title: Text(
                  l10n.settingsRemovePin,
                  style: const TextStyle(color: AppColors.lightError),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRemovePinDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetPinDialog() {
    final l10n = AppLocalizations.of(context);
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.pinDialogTitleSet),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.pinRecommendation,
                    style: Theme.of(dialogCtx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(dialogCtx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: newPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.enterNewPin,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: confirmPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.confirmNewPin,
                      border: const OutlineInputBorder(),
                      errorText: errorMessage,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  final newPin = newPinController.text.trim();
                  final confirmPin = confirmPinController.text.trim();

                  if (newPin.length < 4 || newPin.length > 8) {
                    setDialogState(() {
                      errorMessage = l10n.pinLengthError;
                    });
                    return;
                  }

                  if (newPin != confirmPin) {
                    setDialogState(() {
                      errorMessage = l10n.pinMismatch;
                    });
                    return;
                  }

                  final navigator = Navigator.of(ctx);
                  final pinService = ref.read(pinServiceProvider);
                  await pinService.setPin(newPin: newPin);

                  if (!mounted) return;
                  navigator.pop();
                  await _loadSettings();
                },
                child: Text(l10n.savePin),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePinDialog() {
    final l10n = AppLocalizations.of(context);
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.pinDialogTitleChange),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: currentPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.enterCurrentPin,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.pinRecommendation,
                    style: Theme.of(dialogCtx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(dialogCtx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: newPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.enterNewPin,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: confirmPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.confirmNewPin,
                      border: const OutlineInputBorder(),
                      errorText: errorMessage,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  final navigator = Navigator.of(ctx);
                  final currentPin = currentPinController.text.trim();
                  final newPin = newPinController.text.trim();
                  final confirmPin = confirmPinController.text.trim();

                  final pinService = ref.read(pinServiceProvider);
                  final verify = await pinService.verifyPin(currentPin);
                  if (!verify.success) {
                    setDialogState(() {
                      if (verify.isLockedOut &&
                          verify.remainingLockout != null) {
                        errorMessage = l10n.pinLockoutMessage(
                          verify.remainingLockout!.inSeconds,
                        );
                      } else {
                        errorMessage = l10n.pinIncorrect;
                      }
                    });
                    return;
                  }

                  if (newPin.length < 4 || newPin.length > 8) {
                    setDialogState(() {
                      errorMessage = l10n.pinLengthError;
                    });
                    return;
                  }

                  if (newPin != confirmPin) {
                    setDialogState(() {
                      errorMessage = l10n.pinMismatch;
                    });
                    return;
                  }

                  await pinService.changePin(
                    currentPin: currentPin,
                    newPin: newPin,
                  );

                  if (!mounted) return;
                  navigator.pop();
                  await _loadSettings();
                },
                child: Text(l10n.savePin),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRemovePinDialog() {
    final l10n = AppLocalizations.of(context);
    final currentPinController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.pinDialogTitleRemove),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.enterCurrentPin,
                    border: const OutlineInputBorder(),
                    errorText: errorMessage,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lightError,
                ),
                onPressed: () async {
                  final navigator = Navigator.of(ctx);
                  final currentPin = currentPinController.text.trim();
                  final pinService = ref.read(pinServiceProvider);

                  final verify = await pinService.verifyPin(currentPin);
                  if (!verify.success) {
                    setDialogState(() {
                      if (verify.isLockedOut &&
                          verify.remainingLockout != null) {
                        errorMessage = l10n.pinLockoutMessage(
                          verify.remainingLockout!.inSeconds,
                        );
                      } else {
                        errorMessage = l10n.pinIncorrect;
                      }
                    });
                    return;
                  }

                  await pinService.removePin(currentPin);
                  if (!mounted) return;
                  navigator.pop();
                  await _loadSettings();
                },
                child: Text(l10n.settingsRemovePin),
              ),
            ],
          );
        },
      ),
    );
  }
}
