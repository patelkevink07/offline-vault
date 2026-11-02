import 'package:flutter/material.dart';

/// All color constants for the Offline Vault design system.
///
/// Organized by light and dark palette. Never reference these directly
/// in widgets — use [Theme.of(context).colorScheme] or [AppThemeExtension].
abstract final class AppColors {
  // ── Light palette ──────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF7F6F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightInk = Color(0xFF16201E);
  static const Color lightPrimary = Color(0xFF0F5C5A);
  static const Color lightPrimaryContainer = Color(0xFFD6EBE8);
  static const Color lightSecondary = Color(0xFF3A5654);
  static const Color lightTertiary = Color(0xFFC98A1B);
  static const Color lightTertiaryContainer = Color(0xFFFFF0D4);
  static const Color lightError = Color(0xFFB3402F);
  static const Color lightErrorContainer = Color(0xFFFCE4E0);
  static const Color lightOutline = Color(0xFFE4E1D8);
  static const Color lightOutlineVariant = Color(0xFFD0CDC4);

  // ── Dark palette ───────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF101615);
  static const Color darkSurface = Color(0xFF182120);
  static const Color darkInk = Color(0xFFE8EEEC);
  static const Color darkPrimary = Color(0xFF6CC4BE);
  static const Color darkPrimaryContainer = Color(0xFF0F3D3B);
  static const Color darkSecondary = Color(0xFF8EAFAC);
  static const Color darkTertiary = Color(0xFFE8B44E);
  static const Color darkTertiaryContainer = Color(0xFF4A3510);
  static const Color darkError = Color(0xFFE8806E);
  static const Color darkErrorContainer = Color(0xFF3D1812);
  static const Color darkOutline = Color(0xFF26322F);
  static const Color darkOutlineVariant = Color(0xFF344340);

  // ── Semantic (shared) ──────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D5B);
  static const Color successLight = Color(0xFFD6F0E3);
  static const Color successDark = Color(0xFF5ABA8A);
  static const Color warning = Color(0xFFC98A1B);
  static const Color warningLight = Color(0xFFFFF0D4);
  static const Color warningDark = Color(0xFFE8B44E);

  // ── Group color palette ────────────────────────────────────────────────
  static const List<Color> groupColors = [
    Color(0xFF0F5C5A),
    Color(0xFF2E7D5B),
    Color(0xFF1B6B9C),
    Color(0xFF6C4FA0),
    Color(0xFFC98A1B),
    Color(0xFFB3402F),
    Color(0xFF9C6644),
    Color(0xFF5C6B73),
  ];
}
