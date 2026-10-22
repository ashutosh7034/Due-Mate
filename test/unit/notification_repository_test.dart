import 'package:duemate/core/database/database.dart';
import 'package:duemate/models/app_notification.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/models/task_item.dart';
import 'package:duemate/repositories/notification_repository.dart';
import 'package:duemate/repositories/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late NotificationRepository repo;
  late TaskRepository taskRepo;

  setUp(() {
    db = openTestDatabase();
    repo = NotificationRepository(db);
    taskRepo = TaskRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Notification entries reference a task, so the tasks must exist first.
  Future<void> seedTasks(List<String> ids) async {
    final now = DateTime(2026, 10, 8, 9, 0);
    for (final id in ids) {
      await taskRepo.insert(
        TaskItem(
          id: id,
          title: 'Task $id',
          priority: Priority.medium,
          status: TaskStatus.notStarted,
          recurrenceType: RecurrenceType.none,
          isRecurring: false,
          deadline: now.add(const Duration(days: 1)),
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  AppNotification notification({
    required String id,
    String? taskId,
    NotificationCategory category = NotificationCategory.upcoming,
  }) {
    return AppNotification(
      id: id,
      taskId: taskId,
      category: category,
      title: 'Title $id',
      body: 'Body $id',
      createdAt: DateTime(2026, 10, 8, 9, 0),
    );
  }

  test('watchUnreadCount reflects unread entries', () async {
    await seedTasks(['t1']);
    await repo.add(notification(id: 'a', taskId: 't1'));
    await repo.add(notification(id: 'b', taskId: 't1'));

    expect(await repo.watchUnreadCount().first, 2);
  });

  test('markRead and markAllRead update the unread count', () async {
    await seedTasks(['t1']);
    await repo.add(notification(id: 'a', taskId: 't1'));
    await repo.add(notification(id: 'b', taskId: 't1'));

    await repo.markRead('a');
    expect(await repo.watchUnreadCount().first, 1);

    await repo.markAllRead();
    expect(await repo.watchUnreadCount().first, 0);
  });

  group('addIfAbsentToday (anti-spam)', () {
    setUp(() async {
      await seedTasks(['t1']);
    });

    test('the first insert succeeds', () async {
      final added = await repo.addIfAbsentToday(
        taskId: 't1',
        category: NotificationCategory.overdue,
        notification: notification(
          id: 'a',
          taskId: 't1',
          category: NotificationCategory.overdue,
        ),
      );
      expect(added, isTrue);
    });

    test(
      'a second insert for the same task+category the same day is skipped',
      () async {
        await repo.addIfAbsentToday(
          taskId: 't1',
          category: NotificationCategory.overdue,
          notification: notification(
            id: 'a',
            taskId: 't1',
            category: NotificationCategory.overdue,
          ),
        );
        final added = await repo.addIfAbsentToday(
          taskId: 't1',
          category: NotificationCategory.overdue,
          notification: notification(
            id: 'b',
            taskId: 't1',
            category: NotificationCategory.overdue,
          ),
        );
        expect(added, isFalse);

        final all = await repo.watchAll().first;
        expect(all, hasLength(1));
      },
    );

    test('a different category the same day is allowed', () async {
      await repo.addIfAbsentToday(
        taskId: 't1',
        category: NotificationCategory.overdue,
        notification: notification(
          id: 'a',
          taskId: 't1',
          category: NotificationCategory.overdue,
        ),
      );
      final added = await repo.addIfAbsentToday(
        taskId: 't1',
        category: NotificationCategory.dueSoon,
        notification: notification(
          id: 'b',
          taskId: 't1',
          category: NotificationCategory.dueSoon,
        ),
      );
      expect(added, isTrue);
    });
  });

  test('deleteForTask removes only that task\'s notifications', () async {
    await seedTasks(['t1', 't2']);
    await repo.add(notification(id: 'a', taskId: 't1'));
    await repo.add(notification(id: 'b', taskId: 't2'));

    await repo.deleteForTask('t1');
    final all = await repo.watchAll().first;
    expect(all, hasLength(1));
    expect(all.first.taskId, 't2');
  });
}
