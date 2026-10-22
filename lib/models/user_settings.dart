import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'enums.dart';

/// How dates are rendered in lists and detail views.
enum DateStyle { dayMonth, monthDay }

/// User preferences. Persisted as key/value rows in `app_settings`.
class UserSettings extends Equatable {
  const UserSettings({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.overdueRemindersEnabled = true,
    this.dailySummaryEnabled = true,
    this.upcomingAlertsEnabled = true,
    this.defaultReminderMinutes = 60,
    this.busyHoursEnabled = false,
    this.busyStartHour = 9,
    this.busyEndHour = 17,
    this.weekStartsOnMonday = true,
    this.dateStyle = DateStyle.dayMonth,
    this.use24HourTime = false,
    this.onboardingComplete = false,
    this.defaultAlarmType = 'standard',
    this.defaultRepeatUntilCompleted = false,
    this.defaultRepeatIntervalMinutes = 15,
    this.defaultSound = 'systemDefault',
    this.defaultVibration = 'standard',
  });

  final ThemeMode themeMode;

  /// Master switch. When false, no reminders are scheduled at all.
  final bool notificationsEnabled;

  /// Whether an "after the deadline" nudge may be delivered.
  final bool overdueRemindersEnabled;

  /// A once-a-day summary of the day's tasks.
  final bool dailySummaryEnabled;

  /// Alerts a little before a deadline ("upcoming" alerts).
  final bool upcomingAlertsEnabled;

  /// Default lead time for a new task's first reminder (minutes).
  final int defaultReminderMinutes;

  /// Busy-hours window. Used to *adjust optional* reminders, never to
  /// silently drop critical ones.
  final bool busyHoursEnabled;
  final int busyStartHour;
  final int busyEndHour;

  final bool weekStartsOnMonday;
  final DateStyle dateStyle;
  final bool use24HourTime;
  final bool onboardingComplete;

  final String defaultAlarmType;
  final bool defaultRepeatUntilCompleted;
  final int defaultRepeatIntervalMinutes;
  final String defaultSound;
  final String defaultVibration;

  /// Resolves the string [defaultAlarmType] to the corresponding [AlarmType].
  AlarmType get resolvedDefaultAlarmType => AlarmType.values.firstWhere(
        (t) => t.name == defaultAlarmType,
        orElse: () => AlarmType.standard,
      );

  /// Resolves the string [defaultSound] to the corresponding [NotificationSound].
  NotificationSound get resolvedDefaultSound =>
      NotificationSound.values.firstWhere(
        (s) => s.name == defaultSound,
        orElse: () => NotificationSound.systemDefault,
      );

  /// Resolves the string [defaultVibration] to the corresponding [NotificationVibration].
  NotificationVibration get resolvedDefaultVibration =>
      NotificationVibration.values.firstWhere(
        (v) => v.name == defaultVibration,
        orElse: () => NotificationVibration.standard,
      );

  UserSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? overdueRemindersEnabled,
    bool? dailySummaryEnabled,
    bool? upcomingAlertsEnabled,
    int? defaultReminderMinutes,
    bool? busyHoursEnabled,
    int? busyStartHour,
    int? busyEndHour,
    bool? weekStartsOnMonday,
    DateStyle? dateStyle,
    bool? use24HourTime,
    bool? onboardingComplete,
    String? defaultAlarmType,
    bool? defaultRepeatUntilCompleted,
    int? defaultRepeatIntervalMinutes,
    String? defaultSound,
    String? defaultVibration,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      overdueRemindersEnabled:
          overdueRemindersEnabled ?? this.overdueRemindersEnabled,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      upcomingAlertsEnabled:
          upcomingAlertsEnabled ?? this.upcomingAlertsEnabled,
      defaultReminderMinutes:
          defaultReminderMinutes ?? this.defaultReminderMinutes,
      busyHoursEnabled: busyHoursEnabled ?? this.busyHoursEnabled,
      busyStartHour: busyStartHour ?? this.busyStartHour,
      busyEndHour: busyEndHour ?? this.busyEndHour,
      weekStartsOnMonday: weekStartsOnMonday ?? this.weekStartsOnMonday,
      dateStyle: dateStyle ?? this.dateStyle,
      use24HourTime: use24HourTime ?? this.use24HourTime,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      defaultAlarmType: defaultAlarmType ?? this.defaultAlarmType,
      defaultRepeatUntilCompleted:
          defaultRepeatUntilCompleted ?? this.defaultRepeatUntilCompleted,
      defaultRepeatIntervalMinutes:
          defaultRepeatIntervalMinutes ?? this.defaultRepeatIntervalMinutes,
      defaultSound: defaultSound ?? this.defaultSound,
      defaultVibration: defaultVibration ?? this.defaultVibration,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    notificationsEnabled,
    overdueRemindersEnabled,
    dailySummaryEnabled,
    upcomingAlertsEnabled,
    defaultReminderMinutes,
    busyHoursEnabled,
    busyStartHour,
    busyEndHour,
    weekStartsOnMonday,
    dateStyle,
    use24HourTime,
    onboardingComplete,
    defaultAlarmType,
    defaultRepeatUntilCompleted,
    defaultRepeatIntervalMinutes,
    defaultSound,
    defaultVibration,
  ];
}
