/// 8-point grid spacing system for the Offline Vault design system.
///
/// All spacing values are multiples of 8 to ensure visual consistency.
/// Use these constants instead of arbitrary pixel values.
abstract final class AppSpacing {
  // ── Base unit ──────────────────────────────────────────────────────────
  static const double unit = 8.0;

  // ── Named spacing values ───────────────────────────────────────────────
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // ── Common layout spacing ──────────────────────────────────────────────
  static const double screenPadding = 16.0;
  static const double cardPadding = 16.0;
  static const double listItemSpacing = 8.0;
  static const double sectionSpacing = 24.0;
  static const double dialogPadding = 24.0;

  // ── Radius values ──────────────────────────────────────────────────────
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double chipRadius = 8.0;
  static const double dialogRadius = 28.0;
  static const double bottomSheetRadius = 20.0;
  static const double inputRadius = 12.0;
  static const double thumbnailRadius = 8.0;

  // ── Touch targets ──────────────────────────────────────────────────────
  static const double minTouchTarget = 48.0;
  static const double iconButtonSize = 48.0;

  // ── Elevation ──────────────────────────────────────────────────────────
  static const double elevationNone = 0.0;
  static const double elevationLow = 1.0;
  static const double elevationMedium = 3.0;
  static const double elevationHigh = 6.0;
}
