import 'package:flutter/material.dart';

/// All color constants for the vaultOFF design system.
///
/// Organized by light and dark palette according to the design system specification:
/// - Light: background #F7F6F2, surface #FFFFFF, ink #16201E, secondary text #55625F,
///   primary #0F5C5A, primary container #D6EBE8, amber text #7A4E00 on #FFF0D4,
///   success text #1B5E41 on #D6F0E3, error #B3402F, hairline #E4E1D8.
/// - Dark: background #101615, surface #182120, ink #E8EEEC, secondary text #8B9B97,
///   primary #6CC4BE, primary container #133D3B, hairline #26322F,
///   amber text #FFD27D on #3D2B05, success text #5CE0A0 on #113626, error #FF8575 on #45150E.
abstract final class AppColors {
  // ── Light palette ──────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF7F6F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightInk = Color(0xFF16201E);
  static const Color lightSecondaryText = Color(0xFF55625F);
  static const Color lightPrimary = Color(0xFF0F5C5A);
  static const Color lightPrimaryContainer = Color(0xFFD6EBE8);
  static const Color lightAmberText = Color(0xFF7A4E00);
  static const Color lightAmberContainer = Color(0xFFFFF0D4);
  static const Color lightSuccessText = Color(0xFF1B5E41);
  static const Color lightSuccessContainer = Color(0xFFD6F0E3);
  static const Color lightError = Color(0xFFB3402F);
  static const Color lightErrorContainer = Color(0xFFFCE4E0);
  static const Color lightHairline = Color(0xFFE4E1D8);
  static const Color lightOutline = lightHairline;
  static const Color lightOutlineVariant = Color(0xFFD0CDC4);
  static const Color lightSecondary = Color(0xFF3A5654);
  static const Color lightTertiary = lightAmberText;
  static const Color lightTertiaryContainer = lightAmberContainer;

  // ── Dark palette ───────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF101615);
  static const Color darkSurface = Color(0xFF182120);
  static const Color darkInk = Color(0xFFE8EEEC);
  static const Color darkSecondaryText = Color(0xFF8B9B97);
  static const Color darkPrimary = Color(0xFF6CC4BE);
  static const Color darkPrimaryContainer = Color(0xFF133D3B);
  static const Color darkAmberText = Color(0xFFFFD27D);
  static const Color darkAmberContainer = Color(0xFF3D2B05);
  static const Color darkSuccessText = Color(0xFF5CE0A0);
  static const Color darkSuccessContainer = Color(0xFF113626);
  static const Color darkError = Color(0xFFFF8575);
  static const Color darkErrorContainer = Color(0xFF45150E);
  static const Color darkHairline = Color(0xFF26322F);
  static const Color darkOutline = darkHairline;
  static const Color darkOutlineVariant = Color(0xFF344340);
  static const Color darkSecondary = Color(0xFF8EAFAC);
  static const Color darkTertiary = darkAmberText;
  static const Color darkTertiaryContainer = darkAmberContainer;

  // ── Semantic helpers ───────────────────────────────────────────────────
  static const Color success = lightSuccessText;
  static const Color successLight = lightSuccessContainer;
  static const Color successDark = darkSuccessText;
  static const Color warning = lightAmberText;
  static const Color warningLight = lightAmberContainer;
  static const Color warningDark = darkAmberText;

  // ── Group color palette (8 distinctive colors for vault covers) ─────────
  static const List<Color> groupColors = [
    Color(0xFF0F5C5A), // Deep Teal (Brand)
    Color(0xFF1B5E41), // Pine Green
    Color(0xFF1B6B9C), // Steel Blue
    Color(0xFF6C4FA0), // Royal Plum
    Color(0xFF7A4E00), // Amber Gold
    Color(0xFFB3402F), // Terracotta Brick
    Color(0xFF6E5646), // Warm Bark
    Color(0xFF55625F), // Slate Ink
  ];
}
