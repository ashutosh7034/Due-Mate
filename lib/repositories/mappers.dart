import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show Color;

import '../core/database/database.dart';
import '../models/app_notification.dart';
import '../models/category.dart';
import '../models/enums.dart';
import '../models/reminder.dart';
import '../models/task_item.dart';

/// Translates between Drift row/companion types and the immutable domain
/// models. Keeping this in one file means the mapping rules (UTC storage,
/// colour encoding) are applied consistently.
class Mappers {
  const Mappers._();

  // ---- Categories -------------------------------------------------------

  static Category categoryFromRow(CategoryRow row) => Category(
    id: row.id,
    name: row.name,
    iconKey: row.icon,
    color: Color(row.color),
    isDefault: row.isDefault,
    sortOrder: row.sortOrder,
    createdAt: row.createdAt.toLocal(),
  );

  static CategoriesCompanion categoryToCompanion(Category category) =>
      CategoriesCompanion.insert(
        id: category.id,
        name: category.name,
        icon: Value(category.iconKey),
        color: category.color.toARGB32(),
        isDefault: Value(category.isDefault),
        sortOrder: Value(category.sortOrder),
        createdAt: Value(category.createdAt.toUtc()),
      );

  // ---- Tasks ------------------------------------------------------------

  static TaskItem taskFromRow(TaskRow row) => TaskItem(
    id: row.id,
    title: row.title,
    description: row.description,
    notes: row.notes,
    categoryId: row.categoryId,
    priority: row.priority,
    status: row.status,
    deadline: row.deadline?.toLocal(),
    isRecurring: row.isRecurring,
    recurrenceType: row.recurrenceType,
    recurrenceDays: row.recurrenceDays,
    recurrenceSourceId: row.recurrenceSourceId,
    completedAt: row.completedAt?.toLocal(),
    parentTaskId: row.parentTaskId,
    userId: row.userId,
    alarmType: row.alarmType,
    repeatUntilCompleted: row.repeatUntilCompleted,
    repeatIntervalMinutes: row.repeatIntervalMinutes,
    maxRepeatCount: row.maxRepeatCount,
    currentRepeatCount: row.currentRepeatCount,
    customNotificationTitle: row.customNotificationTitle,
    customNotificationBody: row.customNotificationBody,
    soundChoice: row.soundChoice,
    vibrationChoice: row.vibrationChoice,
    snoozeUntil: row.snoozeUntil?.toLocal(),
    sortOrder: row.sortOrder,
    createdAt: row.createdAt.toLocal(),
    updatedAt: row.updatedAt.toLocal(),
  );

  /// Full companion for an insert/upsert. Timestamps are converted to UTC.
  static TasksCompanion taskToCompanion(TaskItem task) => TasksCompanion.insert(
    id: task.id,
    title: task.title,
    description: Value(task.description),
    notes: Value(task.notes),
    categoryId: Value(task.categoryId),
    priority: task.priority,
    status: task.status,
    deadline: Value(task.deadline?.toUtc()),
    isRecurring: Value(task.isRecurring),
    recurrenceType: task.recurrenceType,
    recurrenceDays: Value(task.recurrenceDays),
    recurrenceSourceId: Value(task.recurrenceSourceId),
    completedAt: Value(task.completedAt?.toUtc()),
    parentTaskId: Value(task.parentTaskId),
    userId: Value(task.userId),
    alarmType: Value(task.alarmType),
    repeatUntilCompleted: Value(task.repeatUntilCompleted),
    repeatIntervalMinutes: Value(task.repeatIntervalMinutes),
    maxRepeatCount: Value(task.maxRepeatCount),
    currentRepeatCount: Value(task.currentRepeatCount),
    customNotificationTitle: Value(task.customNotificationTitle),
    customNotificationBody: Value(task.customNotificationBody),
    soundChoice: Value(task.soundChoice),
    vibrationChoice: Value(task.vibrationChoice),
    snoozeUntil: Value(task.snoozeUntil?.toUtc()),
    sortOrder: Value(task.sortOrder),
    createdAt: Value(task.createdAt.toUtc()),
    updatedAt: Value(task.updatedAt.toUtc()),
  );

  // ---- Reminders --------------------------------------------------------

  static TaskReminder reminderFromRow(ReminderRow row) => TaskReminder(
    id: row.id,
    taskId: row.taskId,
    kind: row.kind,
    minutesBefore: row.minutesBefore,
    scheduledAt: row.scheduledAt.toLocal(),
    notificationId: row.notificationId,
    enabled: row.enabled,
    notifiedAt: row.notifiedAt?.toLocal(),
    createdAt: row.createdAt.toLocal(),
  );

  static RemindersCompanion reminderToCompanion(TaskReminder reminder) =>
      RemindersCompanion.insert(
        id: reminder.id,
        taskId: reminder.taskId,
        kind: reminder.kind,
        minutesBefore: Value(reminder.minutesBefore),
        scheduledAt: reminder.scheduledAt.toUtc(),
        notificationId: reminder.notificationId,
        enabled: Value(reminder.enabled),
        notifiedAt: Value(reminder.notifiedAt?.toUtc()),
        createdAt: Value((reminder.createdAt ?? DateTime.now()).toUtc()),
      );

  // ---- Notifications ----------------------------------------------------

  static AppNotification notificationFromRow(TaskNotificationRow row) =>
      AppNotification(
        id: row.id,
        taskId: row.taskId,
        category: row.category,
        title: row.title,
        body: row.body,
        createdAt: row.createdAt.toLocal(),
        readAt: row.readAt?.toLocal(),
      );

  static TaskNotificationsCompanion notificationToCompanion(
    AppNotification n,
  ) => TaskNotificationsCompanion.insert(
    id: n.id,
    taskId: Value(n.taskId),
    category: n.category,
    title: n.title,
    body: n.body,
    createdAt: Value(n.createdAt.toUtc()),
    readAt: Value(n.readAt?.toUtc()),
  );

  // ---- Settings ---------------------------------------------------------

  static UserSettingsMap settingsFromRows(List<AppSettingRow> rows) =>
      UserSettingsMap({for (final r in rows) r.key: r.value});

  // ---- Enum helpers -----------------------------------------------------

  static int priorityToDb(Priority p) => p.dbValue;
}

/// Thin wrapper so settings parsing stays out of the repository.
class UserSettingsMap {
  const UserSettingsMap(this.values);
  final Map<String, String> values;

  String? operator [](String key) => values[key];
}
