import 'package:drift/drift.dart';

import '../core/database/database.dart';
import '../models/app_notification.dart';
import '../models/enums.dart';
import 'mappers.dart';

/// Storage for the in-app notification centre.
class NotificationRepository {
  NotificationRepository(this._db);

  final AppDatabase _db;

  Stream<List<AppNotification>> watchAll({NotificationCategory? category}) {
    final query = _db.select(_db.taskNotifications)
      ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]);
    if (category != null) {
      query.where((n) => n.category.equalsValue(category));
    }
    return query.watch().map(
      (rows) => rows.map(Mappers.notificationFromRow).toList(),
    );
  }

  Stream<int> watchUnreadCount() {
    final count = _db.taskNotifications.id.count();
    final query = _db.selectOnly(_db.taskNotifications)
      ..addColumns([count])
      ..where(_db.taskNotifications.readAt.isNull());
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<void> add(AppNotification notification) async {
    await _db
        .into(_db.taskNotifications)
        .insert(Mappers.notificationToCompanion(notification));
  }

  /// Inserts only if no notification of [category] already exists for the
  /// task on the same calendar day. Prevents notification spam.
  Future<bool> addIfAbsentToday({
    required String taskId,
    required NotificationCategory category,
    required AppNotification notification,
  }) async {
    final createdUtc = notification.createdAt.toUtc();
    final dayStartUtc = DateTime.utc(
      createdUtc.year,
      createdUtc.month,
      createdUtc.day,
    );
    final existing =
        await (_db.select(_db.taskNotifications)
              ..where(
                (n) =>
                    n.taskId.equals(taskId) &
                    n.category.equalsValue(category) &
                    n.createdAt.isBiggerOrEqualValue(dayStartUtc),
              )
              ..limit(1))
            .get();
    if (existing.isNotEmpty) return false;
    await add(notification);
    return true;
  }

  Future<void> markRead(String id) async {
    await (_db.update(
      _db.taskNotifications,
    )..where((n) => n.id.equals(id))).write(
      TaskNotificationsCompanion(readAt: Value(DateTime.now().toUtc())),
    );
  }

  Future<void> markAllRead() async {
    await (_db.update(
      _db.taskNotifications,
    )..where((n) => n.readAt.isNull())).write(
      TaskNotificationsCompanion(readAt: Value(DateTime.now().toUtc())),
    );
  }

  Future<void> deleteForTask(String taskId) async {
    await (_db.delete(
      _db.taskNotifications,
    )..where((n) => n.taskId.equals(taskId))).go();
  }

  Future<void> clearAll() async {
    await _db.delete(_db.taskNotifications).go();
  }
}
