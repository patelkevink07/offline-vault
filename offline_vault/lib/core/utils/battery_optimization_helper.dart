import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'logger.dart';

class BatteryOptimizationHelper {
  /// Opens the system battery optimization / app details settings screen.
  static Future<void> openBatteryOptimizationSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      const intent = AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (e) {
      VaultLogger.w('Failed to launch IGNORE_BATTERY_OPTIMIZATION_SETTINGS: $e');
      try {
        const fallbackIntent = AndroidIntent(
          action: 'android.settings.SETTINGS',
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await fallbackIntent.launch();
      } catch (e2) {
        VaultLogger.e('Failed to launch fallback settings: $e2');
      }
    }
  }

  /// Displays the explanatory battery optimization guide dialog.
  static Future<void> showGuideDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.batteryOptimizationGuideTitle,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.batteryOptimizationGuideContent,
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openBatteryOptimizationSettings();
            },
            child: Text(l10n.openBatterySettings),
          ),
        ],
      ),
    );
  }
}
