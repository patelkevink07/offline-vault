import 'package:flutter/material.dart';

/// Typography setup for the vaultOFF design system.
///
/// Uses bundled Inter with Noto Sans Gujarati and Noto Sans Devanagari as
/// local offline fallbacks (no runtime Google Fonts fetching).
abstract final class AppTypography {
  static const String fontFamily = 'Inter';
  static const List<String> fontFallbacks = [
    'NotoSansGujarati',
    'NotoSansDevanagari',
  ];

  /// Returns the full Material 3 [TextTheme] built on bundled Inter.
  static TextTheme textTheme(Brightness brightness) {
    final Color inkColor = brightness == Brightness.light
        ? const Color(0xFF16201E)
        : const Color(0xFFE8EEEC);

    final Color secondaryColor = brightness == Brightness.light
        ? const Color(0xFF55625F)
        : const Color(0xFF8B9B97);

    return TextTheme(
      // Large title: 30 / 700 with slight negative tracking
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.20,
        color: inkColor,
      ),

      // Screen title: 20 / 650 (w600)
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.25,
        color: inkColor,
      ),

      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.35,
        color: inkColor,
      ),

      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.35,
        color: inkColor,
      ),

      // Body: 15 / 400 (normal tracking)
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.45,
        color: inkColor,
      ),

      // Body medium: 14 / 400
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.40,
        color: inkColor,
      ),

      // Secondary: 13 / 400
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.35,
        color: secondaryColor,
      ),

      // Section label: 12 / 600 uppercase with 0.06em tracking
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.72,
        height: 1.30,
        color: secondaryColor,
      ),

      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.30,
        color: inkColor,
      ),

      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.35,
        color: inkColor,
      ),
    );
  }
}
