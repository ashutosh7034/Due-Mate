import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Priority of a task.
///
/// Do not reorder: values are persisted by index in the database.
enum Priority {
  low,
  medium,
  high,
  urgent;

  /// Persisted integer value. Stable across releases.
  int get dbValue => index;

  static Priority fromDb(int value) =>
      value >= 0 && value < Priority.values.length
      ? Priority.values[value]
      : Priority.medium;

  String get label => switch (this) {
    Priority.low => 'Low',
    Priority.medium => 'Medium',
    Priority.high => 'High',
    Priority.urgent => 'Urgent',
  };

  /// Sort weight used by presentation queries (lower = more urgent).
  int get weight => switch (this) {
    Priority.urgent => 0,
    Priority.high => 1,
    Priority.medium => 2,
    Priority.low => 3,
  };

  Color get color => switch (this) {
    Priority.low => AppColors.priorityLow,
    Priority.medium => AppColors.priorityMedium,
    Priority.high => AppColors.priorityHigh,
    Priority.urgent => AppColors.priorityUrgent,
  };

  IconData get icon => switch (this) {
    Priority.low => Icons.keyboard_arrow_down_rounded,
    Priority.medium => Icons.drag_handle_rounded,
    Priority.high => Icons.keyboard_arrow_up_rounded,
    Priority.urgent => Icons.priority_high_rounded,
  };

  bool get isImportant => this == Priority.high || this == Priority.urgent;
}

/// Lifecycle status of a task.
///
/// [overdue] is a *derived* status: a task is stored with a non-completed
/// status and becomes overdue when its deadline passes. It is persisted so
/// queries and the notification centre stay consistent.
///
/// Do not reorder: values are persisted by index in the database.
enum TaskStatus {
  notStarted,
  inProgress,
  completed,
  overdue,
  cancelled;

  int get dbValue => index;

  static TaskStatus fromDb(int value) =>
      value >= 0 && value < TaskStatus.values.length
      ? TaskStatus.values[value]
      : TaskStatus.notStarted;

  String get label => switch (this) {
    TaskStatus.notStarted => 'Not started',
    TaskStatus.inProgress => 'In progress',
    TaskStatus.completed => 'Completed',
    TaskStatus.overdue => 'Overdue',
    TaskStatus.cancelled => 'Cancelled',
  };

  bool get isClosed =>
      this == TaskStatus.completed || this == TaskStatus.cancelled;

  bool get isOpen => !isClosed;
}

/// How a task repeats.
///
/// Do not reorder: values are persisted by index in the database.
enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,

  /// Specific weekdays, see `Task.recurrenceDays` (1 = Monday … 7 = Sunday).
  customWeekly;

  int get dbValue => index;

  static RecurrenceType fromDb(int value) =>
      value >= 0 && value < RecurrenceType.values.length
      ? RecurrenceType.values[value]
      : RecurrenceType.none;

  String get label => switch (this) {
    RecurrenceType.none => 'Does not repeat',
    RecurrenceType.daily => 'Daily',
    RecurrenceType.weekly => 'Weekly',
    RecurrenceType.monthly => 'Monthly',
    RecurrenceType.customWeekly => 'Custom days',
  };

  bool get repeats => this != RecurrenceType.none;
}

/// The reason a reminder exists.
///
/// Do not reorder: values are persisted by index in the database.
enum ReminderKind {
  /// Fires `minutesBefore` the deadline.
  beforeDeadline,

  /// Fires exactly at the deadline.
  atDeadline,

  /// Fires shortly after the deadline when the task is still open.
  overdue,

  /// Fires at a user-chosen absolute date/time.
  custom;

  int get dbValue => index;

  static ReminderKind fromDb(int value) =>
      value >= 0 && value < ReminderKind.values.length
      ? ReminderKind.values[value]
      : ReminderKind.beforeDeadline;
}

/// Buckets shown in the in-app notification centre.
///
/// Do not reorder: values are persisted by index in the database.
enum NotificationCategory {
  upcoming,
  dueSoon,
  overdue,
  completed,
  system;

  int get dbValue => index;

  static NotificationCategory fromDb(int value) =>
      value >= 0 && value < NotificationCategory.values.length
      ? NotificationCategory.values[value]
      : NotificationCategory.system;

  String get label => switch (this) {
    NotificationCategory.upcoming => 'Upcoming',
    NotificationCategory.dueSoon => 'Due soon',
    NotificationCategory.overdue => 'Overdue',
    NotificationCategory.completed => 'Completed',
    NotificationCategory.system => 'System',
  };

  IconData get icon => switch (this) {
    NotificationCategory.upcoming => Icons.schedule_rounded,
    NotificationCategory.dueSoon => Icons.timer_outlined,
    NotificationCategory.overdue => Icons.warning_amber_rounded,
    NotificationCategory.completed => Icons.check_circle_outline_rounded,
    NotificationCategory.system => Icons.info_outline_rounded,
  };
}

/// Selectable alarm types for a task.
enum AlarmType {
  /// Standard notification in the Android notification shade.
  standard,

  /// Loud alarm with sound and vibration channel.
  soundVibration,

  /// Urgent alarm that surfaces a dedicated in-app alarm screen when triggered/tapped.
  alarmScreen;

  int get dbValue => index;

  static AlarmType fromDb(int value) =>
      value >= 0 && value < AlarmType.values.length
      ? AlarmType.values[value]
      : AlarmType.standard;

  String get label => switch (this) {
    AlarmType.standard => 'Standard notification',
    AlarmType.soundVibration => 'Sound & vibration alarm',
    AlarmType.alarmScreen => 'Full alarm screen',
  };

  String get description => switch (this) {
    AlarmType.standard => 'Quietly arrives in the notification shade.',
    AlarmType.soundVibration => 'Plays high-priority sound and vibration.',
    AlarmType.alarmScreen =>
      'Opens an interactive full alarm screen with snooze & complete.',
  };

  IconData get icon => switch (this) {
    AlarmType.standard => Icons.notifications_none_rounded,
    AlarmType.soundVibration => Icons.notification_important_rounded,
    AlarmType.alarmScreen => Icons.alarm_rounded,
  };
}

/// Selectable sound choices for notifications.
enum NotificationSound {
  systemDefault,
  silent,
  chime,
  bell,
  horn;

  int get dbValue => index;

  static NotificationSound fromDb(int value) =>
      value >= 0 && value < NotificationSound.values.length
      ? NotificationSound.values[value]
      : NotificationSound.systemDefault;

  String get label => switch (this) {
    NotificationSound.systemDefault => 'System default',
    NotificationSound.silent => 'Silent',
    NotificationSound.chime => 'Gentle chime',
    NotificationSound.bell => 'Clear bell',
    NotificationSound.horn => 'Alert horn',
  };
}

/// Selectable vibration patterns.
enum NotificationVibration {
  standard,
  silent,
  urgent,
  continuous;

  int get dbValue => index;

  static NotificationVibration fromDb(int value) =>
      value >= 0 && value < NotificationVibration.values.length
      ? NotificationVibration.values[value]
      : NotificationVibration.standard;

  String get label => switch (this) {
    NotificationVibration.standard => 'Standard vibration',
    NotificationVibration.silent => 'Silent (no vibration)',
    NotificationVibration.urgent => 'Urgent pulse',
    NotificationVibration.continuous => 'Continuous alert',
  };
}
