import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography scale for Deadline.
///
/// The hierarchy is deliberately strong: a large screen title, a compact
/// section label and a readable body. Numbers (countdowns, progress) use
/// [FontFeature.tabularFigures] so they do not jitter as they tick.
class AppTextStyles {
  const AppTextStyles._();

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
  );

  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.1,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// All-caps section eyebrow, e.g. "OVERDUE".
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.8,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  /// Monospaced-feeling countdown text.
  static const TextStyle countdown = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    height: 1.3,
    fontFeatures: _tabular,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  /// Applies the correct foreground colour for the active brightness.
  static TextTheme textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return TextTheme(
      displayLarge: display.copyWith(color: base),
      headlineMedium: headline.copyWith(color: base),
      titleMedium: title.copyWith(color: base),
      titleSmall: subtitle.copyWith(color: base),
      bodyLarge: body.copyWith(color: base),
      bodyMedium: bodySmall.copyWith(color: base),
      labelLarge: button.copyWith(color: base),
      labelSmall: caption.copyWith(color: muted),
    );
  }
}
