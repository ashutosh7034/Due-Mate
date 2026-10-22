import 'package:drift/drift.dart';

import '../../models/enums.dart';

/// User-defined (or seeded) task categories.
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// Key into `CategoryIcons`, never a raw icon code point.
  /// Raw code points break icon tree-shaking in release builds.
  TextColumn get icon => text().withDefault(const Constant('folder'))();

  /// ARGB colour value.
  IntColumn get color => integer()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tasks and subtasks.
///
/// Subtasks are tasks with a non-null [parentTaskId]. Top-level queries must
/// filter `parentTaskId IS NULL`.
@DataClassName('TaskRow')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get notes => text().nullable()();

  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )();

  IntColumn get priority => intEnum<Priority>()();
  IntColumn get status => intEnum<TaskStatus>()();
  DateTimeColumn get deadline => dateTime().nullable()();

  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  IntColumn get recurrenceType => intEnum<RecurrenceType>()();

  /// CSV of ISO weekday numbers (1 = Monday … 7 = Sunday) for `customWeekly`.
  TextColumn get recurrenceDays => text().nullable()();

  /// Id of the original task in a recurrence chain. Null for the first
  /// occurrence. Prevents duplicate chains when regenerating.
  TextColumn get recurrenceSourceId => text().nullable()();

  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get parentTaskId =>
      text().nullable().references(Tasks, #id, onDelete: KeyAction.cascade)();

  TextColumn get userId =>
      text().nullable().withDefault(const Constant('default_user'))();

  IntColumn get alarmType =>
      intEnum<AlarmType>().withDefault(const Constant(0))();
  BoolColumn get repeatUntilCompleted =>
      boolean().withDefault(const Constant(false))();
  IntColumn get repeatIntervalMinutes =>
      integer().withDefault(const Constant(15))();
  IntColumn get maxRepeatCount => integer().withDefault(const Constant(5))();
  IntColumn get currentRepeatCount =>
      integer().withDefault(const Constant(0))();
  TextColumn get customNotificationTitle => text().nullable()();
  TextColumn get customNotificationBody => text().nullable()();
  IntColumn get soundChoice =>
      intEnum<NotificationSound>().withDefault(const Constant(0))();
  IntColumn get vibrationChoice =>
      intEnum<NotificationVibration>().withDefault(const Constant(0))();
  DateTimeColumn get snoozeUntil => dateTime().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// A scheduled reminder belonging to a task.
@DataClassName('ReminderRow')
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get kind => intEnum<ReminderKind>()();

  /// Minutes before the deadline; null for [ReminderKind.atDeadline],
  /// [ReminderKind.overdue] and [ReminderKind.custom].
  IntColumn get minutesBefore => integer().nullable()();

  /// Absolute time the reminder should fire. Recomputed whenever the task
  /// deadline changes.
  DateTimeColumn get scheduledAt => dateTime()();

  /// Android/iOS notification id. Unique so rescheduling replaces cleanly.
  IntColumn get notificationId => integer()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Set once the app has observed that this reminder's time passed, so the
  /// notification centre is not populated twice for the same reminder.
  DateTimeColumn get notifiedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// In-app notification centre entries. Deliberately distinct from the
/// OS-level scheduled alarms in [Reminders].
@DataClassName('TaskNotificationRow')
class TaskNotifications extends Table {
  TextColumn get id => text()();
  TextColumn get taskId =>
      text().nullable().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get category => intEnum<NotificationCategory>()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get readAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Simple key/value store for user preferences.
@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
