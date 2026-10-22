// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../providers/core_providers.dart';
import '../../repositories/mappers.dart';
import '../database/database.dart';
import '../notifications/reminder_service.dart';

/// Result of validating a DueMate backup JSON payload.
class BackupValidationResult {
  const BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.taskCount = 0,
    this.categoryCount = 0,
    this.reminderCount = 0,
    this.exportedAt,
    this.version = 1,
  });

  final bool isValid;
  final String? errorMessage;
  final int taskCount;
  final int categoryCount;
  final int reminderCount;
  final DateTime? exportedAt;
  final int version;
}

/// Summary of a completed backup restoration.
class RestoreResult {
  const RestoreResult({
    required this.tasksRestored,
    required this.categoriesRestored,
    required this.remindersRestored,
  });

  final int tasksRestored;
  final int categoriesRestored;
  final int remindersRestored;
}

/// Service providing data export and safe validation/import for DueMate.
class BackupService {
  BackupService({
    required AppDatabase db,
    required ReminderService reminderService,
  }) : _db = db,
       _reminderService = reminderService;

  final AppDatabase _db;
  final ReminderService _reminderService;

  static const String appIdentifier = 'DueMate';
  static const int currentVersion = 1;

  /// Exports all tasks, subtasks, categories, and reminders to a formatted JSON string.
  Future<String> exportBackupData() async {
    final categoryRows = await _db.select(_db.categories).get();
    final taskRows = await _db.select(_db.tasks).get();
    final reminderRows = await _db.select(_db.reminders).get();

    final exportMap = <String, dynamic>{
      'app': appIdentifier,
      'version': currentVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'categories': categoryRows
          .map(
            (c) => {
              'id': c.id,
              'name': c.name,
              'icon': c.icon,
              'color': c.color,
              'isDefault': c.isDefault,
              'sortOrder': c.sortOrder,
              'createdAt': c.createdAt.toUtc().toIso8601String(),
            },
          )
          .toList(),
      'tasks': taskRows
          .map(
            (t) => {
              'id': t.id,
              'title': t.title,
              'description': t.description,
              'notes': t.notes,
              'categoryId': t.categoryId,
              'priority': t.priority.name,
              'status': t.status.name,
              'deadline': t.deadline?.toUtc().toIso8601String(),
              'isRecurring': t.isRecurring,
              'recurrenceType': t.recurrenceType.name,
              'recurrenceDays': t.recurrenceDays,
              'recurrenceSourceId': t.recurrenceSourceId,
              'completedAt': t.completedAt?.toUtc().toIso8601String(),
              'parentTaskId': t.parentTaskId,
              'userId': t.userId,
              'alarmType': t.alarmType.name,
              'repeatUntilCompleted': t.repeatUntilCompleted,
              'repeatIntervalMinutes': t.repeatIntervalMinutes,
              'maxRepeatCount': t.maxRepeatCount,
              'currentRepeatCount': t.currentRepeatCount,
              'customNotificationTitle': t.customNotificationTitle,
              'customNotificationBody': t.customNotificationBody,
              'soundChoice': t.soundChoice.name,
              'vibrationChoice': t.vibrationChoice.name,
              'snoozeUntil': t.snoozeUntil?.toUtc().toIso8601String(),
              'sortOrder': t.sortOrder,
              'createdAt': t.createdAt.toUtc().toIso8601String(),
              'updatedAt': t.updatedAt.toUtc().toIso8601String(),
            },
          )
          .toList(),
      'reminders': reminderRows
          .map(
            (r) => {
              'id': r.id,
              'taskId': r.taskId,
              'kind': r.kind.name,
              'minutesBefore': r.minutesBefore,
              'scheduledAt': r.scheduledAt.toUtc().toIso8601String(),
              'notificationId': r.notificationId,
              'enabled': r.enabled,
              'notifiedAt': r.notifiedAt?.toUtc().toIso8601String(),
              'createdAt': r.createdAt.toUtc().toIso8601String(),
            },
          )
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportMap);
  }

  /// Validates a backup JSON string without modifying any database content.
  BackupValidationResult validateBackup(String jsonString) {
    if (jsonString.trim().isEmpty) {
      return const BackupValidationResult(
        isValid: false,
        errorMessage: 'The provided backup content is empty.',
      );
    }

    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'Invalid format: Root must be a JSON object.',
        );
      }

      if (decoded['app'] != appIdentifier) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage:
              'Unrecognized backup: Expected app identifier "$appIdentifier".',
        );
      }

      final version = decoded['version'] as int? ?? 0;
      if (version > currentVersion) {
        return BackupValidationResult(
          isValid: false,
          errorMessage:
              'Backup version $version is newer than current supported version $currentVersion.',
        );
      }

      final dynamic tasksList = decoded['tasks'];
      if (tasksList is! List) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'Corrupt backup: Missing "tasks" array.',
        );
      }

      final dynamic categoriesList = decoded['categories'] ?? [];
      final dynamic remindersList = decoded['reminders'] ?? [];

      DateTime? exportedAt;
      if (decoded['exportedAt'] is String) {
        exportedAt = DateTime.tryParse(decoded['exportedAt'] as String);
      }

      return BackupValidationResult(
        isValid: true,
        taskCount: tasksList.length,
        categoryCount: categoriesList is List ? categoriesList.length : 0,
        reminderCount: remindersList is List ? remindersList.length : 0,
        exportedAt: exportedAt,
        version: version,
      );
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        errorMessage: 'JSON parse error: $e',
      );
    }
  }

  /// Restores tasks and categories from [jsonString].
  ///
  /// Runs inside a database transaction to prevent partial or corrupted states.
  /// If [mergeMode] is false, existing tasks, categories, and reminders are cleared first.
  Future<RestoreResult> restoreBackup(
    String jsonString, {
    bool mergeMode = true,
  }) async {
    final validation = validateBackup(jsonString);
    if (!validation.isValid) {
      throw FormatException(validation.errorMessage ?? 'Invalid backup file');
    }

    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final rawCategories = (decoded['categories'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final rawTasks = (decoded['tasks'] as List).cast<Map<String, dynamic>>();
    final rawReminders = (decoded['reminders'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    int categoriesRestored = 0;
    int tasksRestored = 0;
    int remindersRestored = 0;

    await _db.transaction(() async {
      if (!mergeMode) {
        await _db.delete(_db.taskNotifications).go();
        await _db.delete(_db.reminders).go();
        await _db.delete(_db.tasks).go();
        await _db.delete(_db.categories).go();
      }

      // 1. Insert categories first (dependencies for tasks)
      for (final cat in rawCategories) {
        final id = cat['id'] as String?;
        final name = cat['name'] as String?;
        final color = cat['color'] as int? ?? 0xFF2196F3;
        final icon = cat['icon'] as String? ?? 'folder';
        final isDefault = cat['isDefault'] as bool? ?? false;
        final sortOrder = cat['sortOrder'] as int? ?? 0;
        final createdAt = cat['createdAt'] != null
            ? DateTime.tryParse(cat['createdAt'] as String) ?? DateTime.now()
            : DateTime.now();

        if (id != null && name != null) {
          await _db
              .into(_db.categories)
              .insertOnConflictUpdate(
                CategoriesCompanion.insert(
                  id: id,
                  name: name,
                  icon: Value(icon),
                  color: color,
                  isDefault: Value(isDefault),
                  sortOrder: Value(sortOrder),
                  createdAt: Value(createdAt.toUtc()),
                ),
              );
          categoriesRestored++;
        }
      }

      // 2. Separate top-level tasks and subtasks so foreign key parentTaskId is preserved
      final topLevelTasks = rawTasks
          .where((t) => t['parentTaskId'] == null)
          .toList();
      final subtasks = rawTasks
          .where((t) => t['parentTaskId'] != null)
          .toList();

      Future<void> insertTaskMap(Map<String, dynamic> t) async {
        final id = t['id'] as String?;
        final title = t['title'] as String?;
        if (id == null || title == null) return;

        final priority = Priority.values.firstWhere(
          (p) => p.name == t['priority'],
          orElse: () => Priority.medium,
        );
        final status = TaskStatus.values.firstWhere(
          (s) => s.name == t['status'],
          orElse: () => TaskStatus.notStarted,
        );
        final recurrenceType = RecurrenceType.values.firstWhere(
          (r) => r.name == t['recurrenceType'],
          orElse: () => RecurrenceType.none,
        );

        final deadline = t['deadline'] != null
            ? DateTime.tryParse(t['deadline'] as String)
            : null;
        final completedAt = t['completedAt'] != null
            ? DateTime.tryParse(t['completedAt'] as String)
            : null;
        final createdAt = t['createdAt'] != null
            ? DateTime.tryParse(t['createdAt'] as String) ?? DateTime.now()
            : DateTime.now();
        final updatedAt = t['updatedAt'] != null
            ? DateTime.tryParse(t['updatedAt'] as String) ?? DateTime.now()
            : DateTime.now();

        final alarmType = AlarmType.values.firstWhere(
          (a) => a.name == t['alarmType'],
          orElse: () => AlarmType.standard,
        );
        final soundChoice = NotificationSound.values.firstWhere(
          (s) => s.name == t['soundChoice'],
          orElse: () => NotificationSound.systemDefault,
        );
        final vibrationChoice = NotificationVibration.values.firstWhere(
          (v) => v.name == t['vibrationChoice'],
          orElse: () => NotificationVibration.standard,
        );
        final snoozeUntil = t['snoozeUntil'] != null
            ? DateTime.tryParse(t['snoozeUntil'] as String)
            : null;

        await _db
            .into(_db.tasks)
            .insertOnConflictUpdate(
              TasksCompanion.insert(
                id: id,
                title: title,
                description: Value(t['description'] as String?),
                notes: Value(t['notes'] as String?),
                categoryId: Value(t['categoryId'] as String?),
                priority: priority,
                status: status,
                deadline: Value(deadline?.toUtc()),
                isRecurring: Value(t['isRecurring'] as bool? ?? false),
                recurrenceType: recurrenceType,
                recurrenceDays: Value(t['recurrenceDays'] as String?),
                recurrenceSourceId: Value(t['recurrenceSourceId'] as String?),
                completedAt: Value(completedAt?.toUtc()),
                parentTaskId: Value(t['parentTaskId'] as String?),
                userId: Value(t['userId'] as String? ?? 'default_user'),
                alarmType: Value(alarmType),
                repeatUntilCompleted: Value(
                  t['repeatUntilCompleted'] as bool? ?? false,
                ),
                repeatIntervalMinutes: Value(
                  t['repeatIntervalMinutes'] as int? ?? 15,
                ),
                maxRepeatCount: Value(t['maxRepeatCount'] as int? ?? 5),
                currentRepeatCount: Value(t['currentRepeatCount'] as int? ?? 0),
                customNotificationTitle: Value(
                  t['customNotificationTitle'] as String?,
                ),
                customNotificationBody: Value(
                  t['customNotificationBody'] as String?,
                ),
                soundChoice: Value(soundChoice),
                vibrationChoice: Value(vibrationChoice),
                snoozeUntil: Value(snoozeUntil?.toUtc()),
                sortOrder: Value(t['sortOrder'] as int? ?? 0),
                createdAt: Value(createdAt.toUtc()),
                updatedAt: Value(updatedAt.toUtc()),
              ),
            );
        tasksRestored++;
      }

      for (final t in topLevelTasks) {
        await insertTaskMap(t);
      }
      for (final t in subtasks) {
        await insertTaskMap(t);
      }

      // 3. Reminders
      for (final r in rawReminders) {
        final id = r['id'] as String?;
        final taskId = r['taskId'] as String?;
        final scheduledAtStr = r['scheduledAt'] as String?;
        if (id == null || taskId == null || scheduledAtStr == null) continue;

        final scheduledAt = DateTime.tryParse(scheduledAtStr);
        if (scheduledAt == null) continue;

        final kind = ReminderKind.values.firstWhere(
          (k) => k.name == r['kind'],
          orElse: () => ReminderKind.atDeadline,
        );
        final notificationId = r['notificationId'] as int? ?? 0;
        final enabled = r['enabled'] as bool? ?? true;
        final notifiedAt = r['notifiedAt'] != null
            ? DateTime.tryParse(r['notifiedAt'] as String)
            : null;
        final createdAt = r['createdAt'] != null
            ? DateTime.tryParse(r['createdAt'] as String) ?? DateTime.now()
            : DateTime.now();

        await _db
            .into(_db.reminders)
            .insertOnConflictUpdate(
              RemindersCompanion.insert(
                id: id,
                taskId: taskId,
                kind: kind,
                minutesBefore: Value(r['minutesBefore'] as int?),
                scheduledAt: scheduledAt.toUtc(),
                notificationId: notificationId,
                enabled: Value(enabled),
                notifiedAt: Value(notifiedAt?.toUtc()),
                createdAt: Value(createdAt.toUtc()),
              ),
            );
        remindersRestored++;
      }
    });

    // 4. Reschedule upcoming reminders for open tasks
    final openTasksRows =
        await (_db.select(_db.tasks)..where(
              (t) => t.status.isNotIn([
                TaskStatus.completed.index,
                TaskStatus.cancelled.index,
              ]),
            ))
            .get();

    for (final taskRow in openTasksRows) {
      final taskItem = Mappers.taskFromRow(taskRow);
      if (taskItem.hasDeadline && !taskItem.isClosed) {
        try {
          await _reminderService.resyncFromStored(taskItem);
        } catch (_) {
          // Keep restore going even if an individual notification rescheduling has an error
        }
      }
    }

    return RestoreResult(
      tasksRestored: tasksRestored,
      categoriesRestored: categoriesRestored,
      remindersRestored: remindersRestored,
    );
  }
}

/// Provider for [BackupService].
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    db: ref.watch(databaseProvider),
    reminderService: ref.watch(reminderServiceProvider),
  );
});
