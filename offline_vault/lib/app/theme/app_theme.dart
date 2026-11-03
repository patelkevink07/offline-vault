import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Custom [ThemeExtension] for vaultOFF semantic colors.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.waiting,
    required this.onWaiting,
    required this.waitingContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.hairline,
    required this.secondaryText,
    required this.ink,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color waiting;
  final Color onWaiting;
  final Color waitingContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color hairline;
  final Color secondaryText;
  final Color ink;

  static const light = AppThemeExtension(
    success: AppColors.lightSuccessText,
    onSuccess: AppColors.lightSuccessText,
    successContainer: AppColors.lightSuccessContainer,
    waiting: AppColors.lightAmberText,
    onWaiting: AppColors.lightAmberText,
    waitingContainer: AppColors.lightAmberContainer,
    error: AppColors.lightError,
    onError: AppColors.lightError,
    errorContainer: AppColors.lightErrorContainer,
    hairline: AppColors.lightHairline,
    secondaryText: AppColors.lightSecondaryText,
    ink: AppColors.lightInk,
  );

  static const dark = AppThemeExtension(
    success: AppColors.darkSuccessText,
    onSuccess: AppColors.darkSuccessText,
    successContainer: AppColors.darkSuccessContainer,
    waiting: AppColors.darkAmberText,
    onWaiting: AppColors.darkAmberText,
    waitingContainer: AppColors.darkAmberContainer,
    error: AppColors.darkError,
    onError: AppColors.darkError,
    errorContainer: AppColors.darkErrorContainer,
    hairline: AppColors.darkHairline,
    secondaryText: AppColors.darkSecondaryText,
    ink: AppColors.darkInk,
  );

  @override
  AppThemeExtension copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? waiting,
    Color? onWaiting,
    Color? warning,
    Color? onWarning,
    Color? waitingContainer,
    Color? warningContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? hairline,
    Color? secondaryText,
    Color? ink,
  }) {
    return AppThemeExtension(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      waiting: waiting ?? warning ?? this.waiting,
      onWaiting: onWaiting ?? onWarning ?? this.onWaiting,
      waitingContainer: waitingContainer ?? warningContainer ?? this.waitingContainer,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      hairline: hairline ?? this.hairline,
      secondaryText: secondaryText ?? this.secondaryText,
      ink: ink ?? this.ink,
    );
  }

  // Backward compatibility getters
  Color get warning => waiting;
  Color get onWarning => onWaiting;
  Color get warningContainer => waitingContainer;

  @override
  AppThemeExtension lerp(covariant AppThemeExtension? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      waiting: Color.lerp(waiting, other.waiting, t)!,
      onWaiting: Color.lerp(onWaiting, other.onWaiting, t)!,
      waitingContainer: Color.lerp(waitingContainer, other.waitingContainer, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
    );
  }
}

/// Extension to conveniently access [AppThemeExtension] from [BuildContext].
extension AppThemeExtensionX on BuildContext {
  AppThemeExtension get appColors =>
      Theme.of(this).extension<AppThemeExtension>() ?? AppThemeExtension.light;
}

/// Central theme configuration for vaultOFF.
abstract final class AppTheme {
  static ThemeData get lightTheme => light;
  static ThemeData get darkTheme => dark;

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.lightPrimary,
      brightness: Brightness.light,
    ).copyWith(
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightInk,
      primary: AppColors.lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.lightPrimaryContainer,
      onPrimaryContainer: AppColors.lightPrimary,
      secondary: AppColors.lightSecondary,
      onSecondary: Colors.white,
      tertiary: AppColors.lightAmberText,
      tertiaryContainer: AppColors.lightAmberContainer,
      error: AppColors.lightError,
      errorContainer: AppColors.lightErrorContainer,
      outline: AppColors.lightHairline,
      outlineVariant: AppColors.lightOutlineVariant,
    );

    return _buildThemeData(
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackground: AppColors.lightBackground,
      extension: AppThemeExtension.light,
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.darkPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkInk,
      primary: AppColors.darkPrimary,
      onPrimary: const Color(0xFF101615),
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.darkPrimary,
      secondary: AppColors.darkSecondary,
      onSecondary: Colors.white,
      tertiary: AppColors.darkAmberText,
      tertiaryContainer: AppColors.darkAmberContainer,
      error: AppColors.darkError,
      errorContainer: AppColors.darkErrorContainer,
      outline: AppColors.darkHairline,
      outlineVariant: AppColors.darkOutlineVariant,
    );

    return _buildThemeData(
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackground: AppColors.darkBackground,
      extension: AppThemeExtension.dark,
    );
  }

  static ThemeData _buildThemeData({
    required ColorScheme colorScheme,
    required Brightness brightness,
    required Color scaffoldBackground,
    required AppThemeExtension extension,
  }) {
    final textTheme = AppTypography.textTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffoldBackground,
      extensions: [extension],

      // ── AppBar ───────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 22,
        ),
      ),

      // ── 16 dp Cards with 1 dp hairline border, no shadow ─────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: extension.hairline, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),

      // ── 12 dp Buttons, 48 dp height, 44 dp min target ─────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: extension.hairline, width: 1),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── Input Fields ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: extension.hairline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: extension.hairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
      ),

      // ── Icon Theme (22 dp outlined set) ──────────────────────────────
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 22,
      ),

      // ── Dividers ─────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: extension.hairline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
