import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_settings.dart';
import 'core_providers.dart';

/// Streams the persisted [UserSettings]; defaults are used until loaded.
final settingsProvider = StreamProvider<UserSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

/// Current theme mode, with a safe default while settings load.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).value?.themeMode ?? ThemeMode.system;
});

/// Controller for mutating settings. Writes through to the database and, when
/// relevant, re-syncs reminders.
class SettingsController {
  SettingsController(this._ref);

  final Ref _ref;

  Future<void> update(UserSettings Function(UserSettings) transform) async {
    final repo = _ref.read(settingsRepositoryProvider);
    final current = await repo.load();
    final next = transform(current);
    await repo.save(next);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      update((s) => s.copyWith(themeMode: mode));

  Future<void> setNotificationsEnabled(bool enabled) async {
    await update((s) => s.copyWith(notificationsEnabled: enabled));
    // Re-sync OS notifications to match the new master switch.
    final settings = await _ref.read(settingsRepositoryProvider).load();
    await _ref.read(reminderServiceProvider).applySettingsChange(settings);
  }

  Future<void> setOverdueReminders(bool enabled) =>
      update((s) => s.copyWith(overdueRemindersEnabled: enabled));

  Future<void> setDailySummary(bool enabled) =>
      update((s) => s.copyWith(dailySummaryEnabled: enabled));

  Future<void> setUpcomingAlerts(bool enabled) =>
      update((s) => s.copyWith(upcomingAlertsEnabled: enabled));

  Future<void> setDefaultReminderMinutes(int minutes) =>
      update((s) => s.copyWith(defaultReminderMinutes: minutes));

  Future<void> setBusyHours({
    required bool enabled,
    int? startHour,
    int? endHour,
  }) => update(
    (s) => s.copyWith(
      busyHoursEnabled: enabled,
      busyStartHour: startHour,
      busyEndHour: endHour,
    ),
  );

  Future<void> setWeekStartsOnMonday(bool value) =>
      update((s) => s.copyWith(weekStartsOnMonday: value));

  Future<void> setDateStyle(DateStyle style) =>
      update((s) => s.copyWith(dateStyle: style));

  Future<void> setUse24HourTime(bool value) =>
      update((s) => s.copyWith(use24HourTime: value));

  Future<void> setDefaultAlarmType(String type) =>
      update((s) => s.copyWith(defaultAlarmType: type));

  Future<void> setDefaultRepeatUntilCompleted(bool value) =>
      update((s) => s.copyWith(defaultRepeatUntilCompleted: value));

  Future<void> setDefaultRepeatIntervalMinutes(int minutes) =>
      update((s) => s.copyWith(defaultRepeatIntervalMinutes: minutes));

  Future<void> setDefaultSound(String sound) =>
      update((s) => s.copyWith(defaultSound: sound));

  Future<void> setDefaultVibration(String vibration) =>
      update((s) => s.copyWith(defaultVibration: vibration));

  Future<void> completeOnboarding() =>
      update((s) => s.copyWith(onboardingComplete: true));
}

final settingsControllerProvider = Provider<SettingsController>(
  (ref) => SettingsController(ref),
);
