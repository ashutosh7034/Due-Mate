import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'spacing.dart';

/// Builds the two [ThemeData] objects used by Deadline.
///
/// Components are configured once here (app bar, cards, inputs, chips,
/// navigation bar) so individual screens stay free of styling noise.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = isDark ? _darkScheme() : _lightScheme();
    final textTheme = AppTextStyles.textTheme(brightness);

    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'Roboto',
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: border),
        ),
      ),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: border),
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        side: BorderSide(color: border),
        labelStyle: textTheme.labelSmall,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xxs,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isDark
            ? AppColors.primaryContainerDark
            : AppColors.primaryContainer,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTextStyles.caption.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 23,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: AppElevation.raised,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return isDark ? AppColors.darkTextMuted : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return isDark ? AppColors.darkBorder : AppColors.lightBorder;
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightText,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.darkText : Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.xxs,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        iconColor: scheme.onSurfaceVariant,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
      ),
    );
  }

  static ColorScheme _lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.success,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.successContainer,
      onSecondaryContainer: Color(0xFF103A28),
      tertiary: AppColors.warning,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.warningContainer,
      onTertiaryContainer: Color(0xFF452C08),
      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: AppColors.dangerContainer,
      onErrorContainer: Color(0xFF4A1310),
      surface: AppColors.lightBackground,
      onSurface: AppColors.lightText,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.lightSurface,
      surfaceContainer: AppColors.lightSurfaceVariant,
      surfaceContainerHigh: AppColors.lightSurfaceVariant,
      surfaceContainerHighest: Color(0xFFE7EAEF),
      onSurfaceVariant: AppColors.lightTextMuted,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightBorder,
      shadow: Color(0x1A000000),
      scrim: Color(0x80000000),
      inverseSurface: AppColors.lightText,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.primaryDark,
    );
  }

  static ColorScheme _darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      onPrimary: Color(0xFF14233F),
      primaryContainer: AppColors.primaryContainerDark,
      onPrimaryContainer: Color(0xFFDCE6F7),
      secondary: Color(0xFF64D3A3),
      onSecondary: Color(0xFF0A2A1C),
      secondaryContainer: Color(0xFF1E4433),
      onSecondaryContainer: Color(0xFFCDEEDD),
      tertiary: Color(0xFFE7B567),
      onTertiary: Color(0xFF3B2606),
      tertiaryContainer: Color(0xFF4A3311),
      onTertiaryContainer: Color(0xFFF6DFB8),
      error: Color(0xFFE98A85),
      onError: Color(0xFF44100D),
      errorContainer: Color(0xFF5A211E),
      onErrorContainer: Color(0xFFF7D6D4),
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkText,
      surfaceContainerLowest: Color(0xFF0B0E13),
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkSurfaceVariant,
      surfaceContainerHigh: AppColors.darkSurfaceVariant,
      surfaceContainerHighest: Color(0xFF2C333F),
      onSurfaceVariant: AppColors.darkTextMuted,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorder,
      shadow: Color(0x66000000),
      scrim: Color(0x99000000),
      inverseSurface: AppColors.darkText,
      onInverseSurface: AppColors.lightText,
      inversePrimary: AppColors.primary,
    );
  }
}
