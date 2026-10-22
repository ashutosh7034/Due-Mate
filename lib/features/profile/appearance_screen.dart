import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../models/user_settings.dart';
import '../../providers/settings_provider.dart';
import '../../routes/app_routes.dart';

/// Theme, date format, time format and week-start preferences.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.appearanceSettings),
        builder: (_) => const AppearanceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const UserSettings();
    final controller = ref.read(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.sm,
          Spacing.lg,
          Spacing.xxxl,
        ),
        children: [
          _Label('Theme'),
          RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (value) {
              if (value != null) controller.setThemeMode(value);
            },
            child: Column(
              children: [
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    value: mode,
                    title: Text(_themeLabel(mode), style: AppTextStyles.body),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          _Label('Week starts on'),
          SwitchListTile(
            value: settings.weekStartsOnMonday,
            onChanged: controller.setWeekStartsOnMonday,
            title: Text(
              settings.weekStartsOnMonday ? 'Monday' : 'Sunday',
              style: AppTextStyles.body,
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: Spacing.lg),
          _Label('Date format'),
          RadioGroup<DateStyle>(
            groupValue: settings.dateStyle,
            onChanged: (value) {
              if (value != null) controller.setDateStyle(value);
            },
            child: Column(
              children: [
                for (final style in DateStyle.values)
                  RadioListTile<DateStyle>(
                    value: style,
                    title: Text(
                      _dateStyleLabel(style),
                      style: AppTextStyles.body,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          _Label('Time format'),
          SwitchListTile(
            value: settings.use24HourTime,
            onChanged: controller.setUse24HourTime,
            title: Text(
              settings.use24HourTime ? '24-hour (18:30)' : '12-hour (6:30 PM)',
              style: AppTextStyles.body,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Follow system',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  String _dateStyleLabel(DateStyle style) => switch (style) {
    DateStyle.dayMonth => 'Day first (10 Oct)',
    DateStyle.monthDay => 'Month first (Oct 10)',
  };
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.lg, bottom: Spacing.xs),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
