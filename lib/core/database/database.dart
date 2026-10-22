import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../models/enums.dart';
import 'tables.dart';

part 'database.g.dart';

/// The single SQLite database for Deadline.
///
/// Opened through `drift_flutter`, which picks the right file location per
/// platform. Schema changes must be handled with a migration — never by
/// deleting the database. Bump [schemaVersion] and add an `onUpgrade` step.
@DriftDatabase(
  tables: [Categories, Tasks, Reminders, TaskNotifications, AppSettings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'deadline'));

  /// Test / advanced constructor allowing a custom executor.
  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        final tableInfo = await customSelect("PRAGMA table_info('tasks')")
            .get();
        final hasUserId = tableInfo.any((row) => row.data['name'] == 'user_id');
        if (!hasUserId) {
          await m.addColumn(tasks, tasks.userId);
        }
      }
      if (from < 3) {
        final tableInfo = await customSelect("PRAGMA table_info('tasks')")
            .get();
        final colNames = tableInfo
            .map((row) => row.data['name'] as String)
            .toSet();
        if (!colNames.contains('alarm_type')) {
          await m.addColumn(tasks, tasks.alarmType);
        }
        if (!colNames.contains('repeat_until_completed')) {
          await m.addColumn(tasks, tasks.repeatUntilCompleted);
        }
        if (!colNames.contains('repeat_interval_minutes')) {
          await m.addColumn(tasks, tasks.repeatIntervalMinutes);
        }
        if (!colNames.contains('max_repeat_count')) {
          await m.addColumn(tasks, tasks.maxRepeatCount);
        }
        if (!colNames.contains('current_repeat_count')) {
          await m.addColumn(tasks, tasks.currentRepeatCount);
        }
        if (!colNames.contains('custom_notification_title')) {
          await m.addColumn(tasks, tasks.customNotificationTitle);
        }
        if (!colNames.contains('custom_notification_body')) {
          await m.addColumn(tasks, tasks.customNotificationBody);
        }
        if (!colNames.contains('sound_choice')) {
          await m.addColumn(tasks, tasks.soundChoice);
        }
        if (!colNames.contains('vibration_choice')) {
          await m.addColumn(tasks, tasks.vibrationChoice);
        }
        if (!colNames.contains('snooze_until')) {
          await m.addColumn(tasks, tasks.snoozeUntil);
        }
      }
    },
    beforeOpen: (details) async {
      // Enforce foreign keys (off by default in SQLite).
      await customStatement('PRAGMA foreign_keys = ON');
      await _createIndexes();
    },
  );

  Future<void> _createIndexes() async {
    // Idempotent: CREATE INDEX IF NOT EXISTS.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tasks_deadline ON tasks(deadline)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tasks_parent ON tasks(parent_task_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tasks_user ON tasks(user_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_reminders_task ON reminders(task_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_reminders_scheduled ON reminders(scheduled_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_notifications_created ON task_notifications(created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tasks_category ON tasks(category_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_notifications_task ON task_notifications(task_id)',
    );
  }

  /// Clears every row. Used by the development-only "reset data" action and
  /// by tests. Never wired to a production flow without confirmation.
  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(taskNotifications).go();
      await delete(reminders).go();
      await delete(tasks).go();
      await delete(categories).go();
      await delete(appSettings).go();
    });
  }
}
