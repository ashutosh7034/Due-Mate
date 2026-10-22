import 'package:flutter/material.dart';

/// Centralised colour palette for Deadline.
///
/// Nothing in the app should hardcode a [Color]. Widgets read from the
/// [ColorScheme] produced by [AppTheme], or — for semantic states like
/// "overdue" — from [AppColors] directly so light/dark stay consistent.
class AppColors {
  const AppColors._();

  // Brand — deep indigo/blue. Change these two values to re-skin the app.
  static const Color primary = Color(0xFF2B4A80);
  static const Color primaryPressed = Color(0xFF223B67);
  static const Color primaryContainer = Color(0xFFDCE6F7);
  static const Color onPrimaryContainer = Color(0xFF14233F);

  // Semantic
  static const Color success = Color(0xFF2E9E6B);
  static const Color successContainer = Color(0xFFD8F1E5);
  static const Color warning = Color(0xFFC9821F);
  static const Color warningContainer = Color(0xFFFBEBD2);
  static const Color danger = Color(0xFFC0453F);
  static const Color dangerContainer = Color(0xFFF8DEDC);

  // Priority accents (subtle — never paint whole screens with these)
  static const Color priorityUrgent = Color(0xFFC0453F);
  static const Color priorityHigh = Color(0xFFC9821F);
  static const Color priorityMedium = Color(0xFF2B4A80);
  static const Color priorityLow = Color(0xFF6B7280);

  // Light neutrals
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F2F5);
  static const Color lightBorder = Color(0xFFE3E6EB);
  static const Color lightText = Color(0xFF1B2230);
  static const Color lightTextMuted = Color(0xFF6B7280);

  // Dark neutrals
  static const Color darkBackground = Color(0xFF0F1218);
  static const Color darkSurface = Color(0xFF1A1F29);
  static const Color darkSurfaceVariant = Color(0xFF232A36);
  static const Color darkBorder = Color(0xFF2C333F);
  static const Color darkText = Color(0xFFE9ECF2);
  static const Color darkTextMuted = Color(0xFF98A2B3);

  // Dark-mode brand tint (primary must lighten on dark surfaces)
  static const Color primaryDark = Color(0xFF8FB0E6);
  static const Color primaryContainerDark = Color(0xFF243B63);

  // Dark-mode semantic accents. The light variants above lack contrast on a
  // dark background, so these lighter tints are used instead of duplicating
  // colour literals across widgets.
  static const Color dangerDark = Color(0xFFE98A85);
  static const Color warningDark = Color(0xFFE7B567);
  static const Color successDark = Color(0xFF64D3A3);

  /// The overdue/danger accent for the current [brightness].
  static Color overdueAccent(Brightness brightness) =>
      brightness == Brightness.dark ? dangerDark : danger;

  /// The warning/"due soon" accent for the current [brightness].
  static Color warningAccent(Brightness brightness) =>
      brightness == Brightness.dark ? warningDark : warning;

  /// The success/completed accent for the current [brightness].
  static Color successAccent(Brightness brightness) =>
      brightness == Brightness.dark ? successDark : success;
}
