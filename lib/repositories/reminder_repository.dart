import 'package:drift/drift.dart';

import '../core/database/database.dart';
import '../models/reminder.dart';
import 'mappers.dart';

/// Persistence for reminders. The notification service owns the OS side;
/// this repository owns the database rows.
class ReminderRepository {
  ReminderRepository(this._db);

  final AppDatabase _db;

  Future<List<TaskReminder>> getForTask(String taskId) async {
    final rows =
        await (_db.select(_db.reminders)
              ..where((r) => r.taskId.equals(taskId))
              ..orderBy([(r) => OrderingTerm.asc(r.scheduledAt)]))
            .get();
    return rows.map(Mappers.reminderFromRow).toList();
  }

  Stream<List<TaskReminder>> watchForTask(String taskId) =>
      (_db.select(_db.reminders)
            ..where((r) => r.taskId.equals(taskId))
            ..orderBy([(r) => OrderingTerm.asc(r.scheduledAt)]))
          .watch()
          .map((rows) => rows.map(Mappers.reminderFromRow).toList());

  Future<List<TaskReminder>> getAll() async {
    final rows = await _db.select(_db.reminders).get();
    return rows.map(Mappers.reminderFromRow).toList();
  }

  Stream<List<TaskReminder>> watchAll() =>
      (_db.select(_db.reminders)
            ..orderBy([(r) => OrderingTerm.asc(r.scheduledAt)]))
          .watch()
          .map((rows) => rows.map(Mappers.reminderFromRow).toList());

  Future<void> replaceForTask(
    String taskId,
    List<TaskReminder> reminders,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.reminders,
      )..where((r) => r.taskId.equals(taskId))).go();
      for (final reminder in reminders) {
        await _db
            .into(_db.reminders)
            .insert(Mappers.reminderToCompanion(reminder));
      }
    });
  }

  Future<void> deleteForTask(String taskId) async {
    await (_db.delete(
      _db.reminders,
    )..where((r) => r.taskId.equals(taskId))).go();
  }

  Future<void> upsert(TaskReminder reminder) async {
    await _db
        .into(_db.reminders)
        .insertOnConflictUpdate(Mappers.reminderToCompanion(reminder));
  }

  /// Reminders whose moment has passed but which have not yet been surfaced
  /// in the in-app notification centre.
  Future<List<TaskReminder>> getDueUnnotified(DateTime now) async {
    final rows =
        await (_db.select(_db.reminders)
              ..where(
                (r) =>
                    r.enabled.equals(true) &
                    r.notifiedAt.isNull() &
                    r.scheduledAt.isSmallerOrEqualValue(now.toUtc()),
              )
              ..orderBy([(r) => OrderingTerm.asc(r.scheduledAt)]))
            .get();
    return rows.map(Mappers.reminderFromRow).toList();
  }

  Future<void> markNotified(String id, DateTime at) async {
    await (_db.update(_db.reminders)..where((r) => r.id.equals(id))).write(
      RemindersCompanion(notifiedAt: Value(at.toUtc())),
    );
  }

  /// All enabled reminder ids, used to detect orphaned OS alarms.
  Future<Set<int>> allNotificationIds() async {
    final rows = await _db.select(_db.reminders).get();
    return rows.map((r) => r.notificationId).toSet();
  }
}
