import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../core/database/database.dart';
import '../models/user_settings.dart';

/// Persists [UserSettings] as key/value rows and streams changes.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const _kThemeMode = 'theme_mode';
  static const _kNotifications = 'notifications_enabled';
  static const _kOverdue = 'overdue_reminders_enabled';
  static const _kDailySummary = 'daily_summary_enabled';
  static const _kUpcoming = 'upcoming_alerts_enabled';
  static const _kDefaultReminder = 'default_reminder_minutes';
  static const _kBusyEnabled = 'busy_hours_enabled';
  static const _kBusyStart = 'busy_start_hour';
  static const _kBusyEnd = 'busy_end_hour';
  static const _kWeekStart = 'week_starts_monday';
  static const _kDateStyle = 'date_style';
  static const _kUse24h = 'use_24h';
  static const _kOnboarding = 'onboarding_complete';
  static const _kDefaultAlarmType = 'default_alarm_type';
  static const _kDefaultRepeatUntilCompleted = 'default_repeat_until_completed';
  static const _kDefaultRepeatIntervalMinutes =
      'default_repeat_interval_minutes';
  static const _kDefaultSound = 'default_sound';
  static const _kDefaultVibration = 'default_vibration';

  Stream<UserSettings> watch() => _db
      .select(_db.appSettings)
      .watch()
      .map((rows) => _decode({for (final r in rows) r.key: r.value}));

  Future<UserSettings> load() async {
    final rows = await _db.select(_db.appSettings).get();
    return _decode({for (final r in rows) r.key: r.value});
  }

  Future<void> save(UserSettings settings) async {
    final entries = <String, String>{
      _kThemeMode: settings.themeMode.name,
      _kNotifications: settings.notificationsEnabled.toString(),
      _kOverdue: settings.overdueRemindersEnabled.toString(),
      _kDailySummary: settings.dailySummaryEnabled.toString(),
      _kUpcoming: settings.upcomingAlertsEnabled.toString(),
      _kDefaultReminder: settings.defaultReminderMinutes.toString(),
      _kBusyEnabled: settings.busyHoursEnabled.toString(),
      _kBusyStart: settings.busyStartHour.toString(),
      _kBusyEnd: settings.busyEndHour.toString(),
      _kWeekStart: settings.weekStartsOnMonday.toString(),
      _kDateStyle: settings.dateStyle.name,
      _kUse24h: settings.use24HourTime.toString(),
      _kOnboarding: settings.onboardingComplete.toString(),
      _kDefaultAlarmType: settings.defaultAlarmType,
      _kDefaultRepeatUntilCompleted: settings.defaultRepeatUntilCompleted
          .toString(),
      _kDefaultRepeatIntervalMinutes: settings.defaultRepeatIntervalMinutes
          .toString(),
      _kDefaultSound: settings.defaultSound,
      _kDefaultVibration: settings.defaultVibration,
    };

    await _db.batch((b) {
      for (final entry in entries.entries) {
        b.insert(
          _db.appSettings,
          AppSettingsCompanion.insert(key: entry.key, value: entry.value),
          onConflict: DoUpdate(
            (_) => AppSettingsCompanion(value: Value(entry.value)),
          ),
        );
      }
    });
  }

  UserSettings _decode(Map<String, String> map) {
    int intOf(String key, int fallback) =>
        int.tryParse(map[key] ?? '') ?? fallback;
    bool boolOf(String key, bool fallback) {
      final v = map[key];
      if (v == null) return fallback;
      return v == 'true';
    }

    ThemeMode themeMode = ThemeMode.system;
    switch (map[_kThemeMode]) {
      case 'light':
        themeMode = ThemeMode.light;
      case 'dark':
        themeMode = ThemeMode.dark;
      case 'system':
        themeMode = ThemeMode.system;
    }

    DateStyle dateStyle = DateStyle.dayMonth;
    if (map[_kDateStyle] == DateStyle.monthDay.name) {
      dateStyle = DateStyle.monthDay;
    }

    return UserSettings(
      themeMode: themeMode,
      notificationsEnabled: boolOf(_kNotifications, true),
      overdueRemindersEnabled: boolOf(_kOverdue, true),
      dailySummaryEnabled: boolOf(_kDailySummary, true),
      upcomingAlertsEnabled: boolOf(_kUpcoming, true),
      defaultReminderMinutes: intOf(_kDefaultReminder, 60),
      busyHoursEnabled: boolOf(_kBusyEnabled, false),
      busyStartHour: intOf(_kBusyStart, 9),
      busyEndHour: intOf(_kBusyEnd, 17),
      weekStartsOnMonday: boolOf(_kWeekStart, true),
      dateStyle: dateStyle,
      use24HourTime: boolOf(_kUse24h, false),
      onboardingComplete: boolOf(_kOnboarding, false),
      defaultAlarmType: map[_kDefaultAlarmType] ?? 'standard',
      defaultRepeatUntilCompleted: boolOf(_kDefaultRepeatUntilCompleted, false),
      defaultRepeatIntervalMinutes: intOf(_kDefaultRepeatIntervalMinutes, 15),
      defaultSound: map[_kDefaultSound] ?? 'systemDefault',
      defaultVibration: map[_kDefaultVibration] ?? 'standard',
    );
  }
}
